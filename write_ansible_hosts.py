#!/usr/bin/python3
import pylxd
import configparser

def get_groups():
    groups = {}
    for container in pylxd.Client().containers.all():
        if container.name.startswith('ans-'):
            group = container.name.split('-')[1].rstrip('1234567890')
            for addr in container.state().network['eth0']['addresses']:
                if addr['family'] == 'inet':
                    try:
                        groups[group].append(addr['address'])
                    except KeyError:
                        groups[group] = [addr['address']]
    return groups

config = configparser.ConfigParser(allow_no_value=True)
groups = get_groups()

for section, addresses in get_groups().items():
    config.add_section(section)
    for addr in addresses:
        config.set(section, addr)
config.add_section('multi:children')
for section, addresses in get_groups().items():
    config.set('multi:children', section)
config.add_section('multi:vars')
config.set('multi:vars', 'ansible_ssh_user', 'ansuser')
config.add_section('cookie')
config.set('cookie', 'cookie.gnuoy.eu')
config.add_section('linode:children')
config.set('linode:children', 'cookie')
config.add_section('linode:vars')
config.set('linode:vars', 'ansible_ssh_user', 'liam')

# Writing our configuration file to 'example.cfg'
with open('/etc/ansible/hosts', 'w') as configfile:
    config.write(configfile)
