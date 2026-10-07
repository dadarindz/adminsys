#!/bin/bash
# verif_tp.sh - verifie automatiquement le tableau de l'exercice 8
# Usage : sudo bash verif_tp.sh
REUSSIS=0
ECHECS=0

ok() { echo "[OK] $1"; REUSSIS=$(( REUSSIS + 1 )); }
ko() { echo "[KO] $1"; ECHECS=$(( ECHECS + 1 )); }

# Un acces qui doit etre REFUSE
if sudo -u bob test -r /srv/partage/rapport.txt; then
  ko "bob peut lire rapport.txt (attendu : refuse)"
else
  ok "bob ne peut pas lire rapport.txt"
fi

# Un acces qui doit etre AUTORISE
if sudo -u carole test -w /srv/partage/rapport.txt; then
  ok "carole peut modifier rapport.txt"
else
  ko "carole ne peut pas modifier rapport.txt (attendu : autorise)"
fi

# bob ne doit pas pouvoir lister /srv/partage (il a seulement x)
if sudo -u bob ls /srv/partage > /dev/null 2>&1; then
  ko "bob peut lister /srv/partage (attendu : refuse)"
else
  ok "bob ne peut pas lister /srv/partage"
fi

# carole doit pouvoir modifier commun/nouveau.txt (ACL par defaut du groupe projet)
if sudo -u carole test -w /srv/partage/commun/nouveau.txt; then
  ok "carole peut modifier commun/nouveau.txt"
else
  ko "carole ne peut pas modifier commun/nouveau.txt (attendu : autorise)"
fi

# bob lit confidentiel.txt grace a l'ACL (et plus avec sudo less)
if sudo -u bob test -r /srv/partage/confidentiel.txt; then
  ok "bob peut lire confidentiel.txt"
else
  ko "bob ne peut pas lire confidentiel.txt (attendu : autorise)"
fi

# ACL : l'entree par defaut du groupe projet doit etre sur commun
if getfacl -p /srv/partage/commun 2>/dev/null | grep -q "^default:group:projet:rwx"; then
  ok "ACL par defaut group:projet presente sur commun"
else
  ko "ACL par defaut group:projet absente sur commun"
fi

# Regle sudo : bob peut redemarrer cron ...
if sudo -l -U bob | grep -q "/usr/bin/systemctl restart cron"; then
  ok "bob peut redemarrer cron avec sudo"
else
  ko "bob ne peut pas redemarrer cron avec sudo (attendu : autorise)"
fi

# ... mais rien d'autre (ni ssh, ni less)
if sudo -l -U bob | grep -Eq "restart ssh|less|\(ALL"; then
  ko "bob a plus de droits sudo que prevu"
else
  ok "bob n'a pas d'autre droit sudo (pas de ssh, pas de less)"
fi

# SSH : mot de passe interdit, root interdit, groupes autorises
if sshd -T | grep -qx "passwordauthentication no"; then
  ok "sshd refuse les mots de passe"
else
  ko "sshd accepte encore les mots de passe"
fi

if sshd -T | grep -qx "permitrootlogin no"; then
  ok "sshd refuse root"
else
  ko "sshd accepte root"
fi

if sshd -T | grep -qx "allowgroups projet" && sshd -T | grep -qx "allowgroups sudo"; then
  ok "AllowGroups projet sudo"
else
  ko "AllowGroups mal configure"
fi

echo "--- $REUSSIS reussi(s), $ECHECS echec(s)"
[ "$ECHECS" -eq 0 ]
