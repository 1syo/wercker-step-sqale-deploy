#!/bin/sh
if [ ! -n "$WERCKER_SQALE_DEPLOY_KEYNAME" ]; then
  fail 'Please specify keyname property.'
fi

if [ ! -n "$WERCKER_SQALE_DEPLOY_REPOSITORY" ]; then
  fail 'Please specify repository property.'
fi

if [ ! -d "$HOME/.ssh" ]; then
  mkdir -p $HOME/.ssh
fi

private_key_path=`mktemp`
private_key_name=$(eval echo "\$${WERCKER_SQALE_DEPLOY_KEYNAME}_PRIVATE")

if [ ! -n "$private_key_name" ]; then
  fail 'Private key was not found'
fi

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
git remote add sqale ssh://gateway_sqale_jp$WERCKER_SQALE_DEPLOY_REPOSITORY
git checkout -b ${now}

info "Deployment to sqale"
git push -f sqale ${now}:master
exit_code=$?

rm $private_key_path

if [ $exit_code -ne 0 ]; then
  fail 'Deployment failed.'
else
  success "Finished successfully!"
fi
