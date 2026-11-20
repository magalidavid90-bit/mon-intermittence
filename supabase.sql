-- Mon Intermittence : stockage chiffré pour la synchronisation téléphone + ordinateur.
-- (Option future, pas encore activée dans l'appli : supabaseUrl et supabaseCle sont vides.)
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
