#
# This salt state adds the requisite iptables exceptions to the
#      INPUT filters to allow communications between the local
#      Splunk client-agent and the remote Splunk Enterprise
#      collector service.
#
#################################################################

{#- ################################## #}
{#- # Optional parameters from pillar  #}
{#- ################################## #}

{#- # Get splunk ports from pillar, or default to `[ 8089, 9997 ]` #}

{%- set splunkPorts = salt['pillar.get'](
  'splunk:ports', 
  [ '8089', '9997' ]) %}

{#- ################################## #}
{#- # Internal variables               #}
{#- ################################## #}

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
