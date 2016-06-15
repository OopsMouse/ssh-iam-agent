#!/bin/bash
PATH=$PATH:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin
# current users in host.
iam_users=$(find /home -maxdepth 1 -type d | grep '^/home/' | sed -e 's/^\/home\/\(.\)/\1/')
for iam_user in $iam_users; do
  user_home="/home/$iam_user"
  user_ssh_dir="$user_home/.ssh"
  # setup ssh directory
  mkdir -p "$user_ssh_dir"
  chown -R "$iam_user" "$user_home"
  chmod -R 700 "$user_home"
  # setup ssh key
  touch "$user_ssh_dir/authorized_keys"
  touch "$user_ssh_dir/new_authorized_keys"
  key_ids=$(aws iam list-ssh-public-keys --user-name $iam_user | jq -r 'select(.SSHPublicKeys[].Status == "Active") | .SSHPublicKeys[].SSHPublicKeyId')
  if [ "$key_ids" == "" ]; then
    continue
  fi
  for key_id in $key_ids; do
    aws iam get-ssh-public-key --user-name $iam_user --ssh-public-key-id $key_id --encoding SSH | jq -r '.SSHPublicKey.SSHPublicKeyBody' >> "$user_ssh_dir/new_authorized_keys"
  done
  keys_diff=$(diff "$user_ssh_dir/authorized_keys" "$user_ssh_dir/new_authorized_keys")
  if [ "$keys_diff" == "" ]; then
    rm -f "$user_ssh_dir/new_authorized_keys"
    continue
  fi
  rm -f "$user_ssh_dir/authorized_keys"
  mv "$user_ssh_dir/new_authorized_keys" "$user_ssh_dir/authorized_keys"
  chown "$iam_user" "$user_ssh_dir/authorized_keys"
  chmod 700 "$user_ssh_dir/authorized_keys"
  ps aux | grep "sshd: $iam_user@pts/" | grep -v grep | awk '{ print "kill -9", $2 }' | sh
done
