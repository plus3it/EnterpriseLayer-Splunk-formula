#
# This salt state adds the requisite iptables exceptions to the
#      INPUT filters to allow communications between the local
#      Splunk client-agent and the remote Splunk Enterprise 
#      collector service.
#
#################################################################

{%- set splunkPorts = [ '8089', '9997' ] %}
{%- set fwFile = '/etc/sysconfig/iptables' %}
{%- set ruleChain = 'OUTPUT' %}

splunk-FWnotify:
  cmd.run:
    - name: 'echo "Inserting requisite rules into iptables"'

{%- for outPort in splunkPorts %}
  {%- set lookFor = ruleChain + ' .* --dport ' + outPort %}

splunk-manage-{{ outPort }}:
  iptables.append:
    - table: filter
    - chain: {{ ruleChain }}
    - jump: ACCEPT
    - match:
        - state
        - comment
    - comment: "remote management of Splunk client-agent"
    - connstate: NEW
    - dport: {{ outPort }}
    - proto: tcp
    - save: True
    - unless: 'grep -qw -- "{{ lookFor }}" {{ fwFile }}'
{%- endfor %}
