#!/bin/sh
set -e

if [ ! "$WERCKER" = true ]; then
  fail "Outside the wercker environment, not deploy."
fi

if [ ! -d "$HOME/.ssh" ]; then
  mkdir -p $HOME/.ssh
fi

private_key_path=`mktemp`
private_key_name=$(eval echo "\$${WERCKER_SQALE_KEYNAME}_PRIVATE")
echo -e "$private_key_name" > $private_key_path
chmod 600 $private_key_path
info "Set up the private key."

cat <<-__CONFIG__ > $HOME/.ssh/config
  Host gateway_sqale_jp
    User sqale
    Hostname gateway.sqale.jp
    Port 2222
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no
    IdentityFile ${private_key_path}
__CONFIG__
chmod 600 $HOME/.ssh/config
info "Set up the ssh config."

now=`date +%s`
rm -rf .bundle
git remote add sqale ssh://gateway_sqale_jp$WERCKER_SQALE_REPOSITORY
git checkout -b ${now}
git push sqale ${now}:master
success "Deployment to sqale finished successfully!"
