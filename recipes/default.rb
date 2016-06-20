#
# Cookbook Name:: ssh-iam-agent
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

node['ssh-iam-agent']['users'].each { |user_name|
  group 'ops' do
    action :create
  end

  user user_name do
    group 'ops'
    home "/home/#{user_name}"
    password nil
    shell '/bin/bash'
    supports :manage_home => true
    action [:create, :manage]
  end

  file '/etc/sudoers.d/ops' do
    owner 'root'
    group 'root'
    mode 0440
    content "%ops ALL=(ALL) NOPASSWD: ALL\n"
  end
}

package 'jq' do
  action :install
end

template '/opt/authorized_keys_command.sh' do
  source '/opt/authorized_keys_command.sh'
  owner 'root'
  group 'root'
  mode 00755
end

cron 'cron authorized_keys_command.sh' do
  minute '10'
  command '/opt/authorized_keys_command.sh'
end
