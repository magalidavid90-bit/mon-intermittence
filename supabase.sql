-- Mon Intermittence : stockage chiffré pour la synchronisation téléphone + ordinateur.
-- À coller une seule fois dans Supabase > SQL Editor > New query, puis « Run ».
--
-- Le serveur ne stocke que des paquets chiffrés sur l'appareil de l'utilisateur.
-- Il ne connaît ni le code de synchronisation, ni le contenu, ni l'identité des personnes.
-- La table n'est pas lisible directement : on ne passe que par les trois fonctions ci-dessous,
-- et il faut connaître l'identifiant exact d'un coffre (calculé à partir du code secret) pour le lire.

create table if not exists public.coffres (
  id          text primary key check (id ~ '^[0-9a-f]{64}$'),
  donnees     text not null check (length(donnees) < 5000000),
  maj         bigint not null,
  modifie_le  timestamptz not null default now()
);

alter table public.coffres enable row level security;
revoke all on public.coffres from anon, authenticated;

create or replace function public.lire_coffre(p_id text)
returns table (donnees text, maj bigint)
language sql security definer set search_path = public
as $$
  select c.donnees, c.maj from public.coffres c where c.id = p_id;
$$;

-- Écrit le coffre seulement si personne ne l'a modifié depuis la dernière lecture (p_base).
-- Renvoie p_maj si l'écriture a eu lieu, sinon la version actuelle du serveur.
create or replace function public.ecrire_coffre(p_id text, p_donnees text, p_maj bigint, p_base bigint)
returns bigint
language plpgsql security definer set search_path = public
as $$
declare actuel bigint;
begin
  select c.maj into actuel from public.coffres c where c.id = p_id for update;
  if actuel is not null and actuel is distinct from p_base then
    return actuel;
  end if;
  insert into public.coffres (id, donnees, maj) values (p_id, p_donnees, p_maj)
  on conflict (id) do update set donnees = excluded.donnees, maj = excluded.maj, modifie_le = now();
  return p_maj;
end;
$$;

create or replace function public.supprimer_coffre(p_id text)
returns void
language sql security definer set search_path = public
as $$
  delete from public.coffres where id = p_id;
$$;

grant execute on function public.lire_coffre(text) to anon, authenticated;
grant execute on function public.ecrire_coffre(text, text, bigint, bigint) to anon, authenticated;
grant execute on function public.supprimer_coffre(text) to anon, authenticated;

-- =====================================================================
-- Clés de la version complète : chacune ne s'active que sur UN appareil.
-- Seule l'empreinte (h) de chaque clé est stockée, jamais la clé elle-même.
-- Pour libérer une clé (le testeur a changé de téléphone) : Table Editor > licences,
-- vider la case « appareil » de la ligne concernée.
-- Pour prolonger ou arrêter un essai : modifier « fin » (vide = à vie).
-- Vous pouvez remplacer « Testeur 1 »… par le nom de la personne qui a reçu la clé.
-- =====================================================================

create table if not exists public.licences (
  h          text primary key check (h ~ '^[0-9a-f]{64}$'),
  nom        text,
  fin        date,
  appareil   text,
  active_le  timestamptz
);
alter table public.licences enable row level security;
revoke all on public.licences from anon, authenticated;

create or replace function public.activer_licence(p_h text, p_appareil text)
returns json
language plpgsql security definer set search_path = public
as $$
declare l public.licences;
begin
  if p_appareil !~ '^[0-9a-f]{32}$' then return json_build_object('ok', false, 'raison', 'inconnue'); end if;
  select * into l from public.licences where h = p_h for update;
  if not found then return json_build_object('ok', false, 'raison', 'inconnue'); end if;
  if l.fin is not null and l.fin < current_date then
    return json_build_object('ok', false, 'raison', 'expiree', 'fin', l.fin);
  end if;
  if l.appareil is null then
    update public.licences set appareil = p_appareil, active_le = now() where h = p_h;
  elsif l.appareil <> p_appareil then
    return json_build_object('ok', false, 'raison', 'deja_utilisee');
  end if;
  return json_build_object('ok', true, 'fin', l.fin);
end;
$$;

create or replace function public.verifier_licence(p_h text, p_appareil text)
returns json
language plpgsql security definer set search_path = public
as $$
declare l public.licences;
begin
  select * into l from public.licences where h = p_h;
  if not found then return json_build_object('ok', false, 'raison', 'inconnue'); end if;
  if l.appareil is distinct from p_appareil then return json_build_object('ok', false, 'raison', 'autre_appareil'); end if;
  if l.fin is not null and l.fin < current_date then
    return json_build_object('ok', false, 'raison', 'expiree', 'fin', l.fin);
  end if;
  return json_build_object('ok', true, 'fin', l.fin);
end;
$$;

grant execute on function public.activer_licence(text, text) to anon, authenticated;
grant execute on function public.verifier_licence(text, text) to anon, authenticated;

insert into public.licences (h, nom, fin) values
  ('83cf656f6cbc9b4193d1ce344b1fd67ab736d88fe2834dc2b2d54c84b7e71e26', 'Pass à vie 1', null),
  ('db2d650eff4e1a224596e2725e049cd95e5658ed65ae18f0048b4311d96ea0a2', 'Pass à vie 2', null),
  ('e0a35c713a1ad29098e4287c7dad575b161b38c9bb9ce3a2a0a4fc483fcde862', 'Testeur 1', '2027-11-30'),
  ('852874d1a42b5de3930f9ca29bcdbe7a6315d72869544a896d49eca3d00d0aa5', 'Testeur 2', '2027-11-30'),
  ('5adce55de499bd6cc058496ca72a44cfc943d900f718f0c89d6e90adf41ba749', 'Testeur 3', '2027-11-30'),
  ('4e3cf126b2d11f09e804c686f76250bbf40e57775748fdde775b061219bbe00f', 'Testeur 4', '2027-11-30'),
  ('505ca7f4281e20df509f82cd481386d0ad16c6d608844d141f9a531aa53fd97d', 'Testeur 5', '2027-11-30'),
  ('d882d131426bc59d83577c7be03b359c8299b311feb40f8757bcdcf85f86a95a', 'Testeur 6', '2027-11-30'),
  ('764e284250c8ba0a8df5ac2f18b02bce9cf7ab92f28858feb8ad0d1e2b95d7a9', 'Testeur 7', '2027-11-30'),
  ('a376e21a8a3c9e35a77cf2a918ab9f214814cc1eae148b0b3e87e866ea201fd0', 'Testeur 8', '2027-11-30'),
  ('5f65f6188d5b30484a7e586aab902da2af746d87401a707453acb60c09c0ded5', 'Testeur 9', '2027-11-30'),
  ('b19e556f0727809891ed9ae615ceeca9fe438241d66e870eb99f4b675d432ac1', 'Testeur 10', '2027-11-30')
on conflict (h) do nothing;
