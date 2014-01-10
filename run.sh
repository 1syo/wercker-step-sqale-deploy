if [ ! -n "$WERCKER_SQALE_DEPLOY_KEYNAME" ]; then
  fail 'Please specify keyname property.'
fi

if [ ! -n "$WERCKER_SQALE_DEPLOY_REPOSITORY" ]; then
  fail 'Please specify repository property.'
fi

private_key_path=`mktemp`
private_key_name=$(eval echo "\$${WERCKER_SQALE_DEPLOY_KEYNAME}_PRIVATE")

if [ ! -n "$private_key_name" ]; then
  fail 'Private key was not found'
fi

echo -e "$private_key_name" > $private_key_path
chmod 600 $private_key_path
info "Set up the private key."

ssh_option_path=`mktemp`
cat <<-__OPTION__ > $ssh_option_path
#! /bin/sh
exec ssh -oIdentityFile=${private_key_path} -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no "\$@"
__OPTION__
chmod +x $ssh_option_path
info "Set up ssh options."

now=`date +%s`
rm -rf .bundle
git remote add sqale "ssh://sqale@gateway_sqale_jp:2222${WERCKER_SQALE_DEPLOY_REPOSITORY}"
git checkout -b ${now}

info "Deployment to sqale"
GIT_SSH=$ssh_option_path git push -f sqale ${now}:master
exit_code=$?

rm $private_key_path

if [ $exit_code -ne 0 ]; then
  fail 'Deployment failed.'
else
  success "Finished successfully!"
fi
