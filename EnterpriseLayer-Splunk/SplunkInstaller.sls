#
# This salt state attempts to download and install the correct
#      Splunk client-agent for the host's architecture. Further,
#      the state will attempt to locate and install appropriate
#      client configuration files for its installation-context.
#
#      These states draw their context cues from grain and/or
#      pillar definitions not bundled with these states. These
#      externalized definitions are bundled separately from
#      these formulae to ensure portability of the states
#      without having to hard-code potentially sensitive
#      information into the formula's state definitions.
#
#      To use these states, ensure that the deployment-target's
#      grains/pillars make suitable values for:
#
#         deployment_type
#         deployment_env
#         repo_splunk
#
#      available to these state-definitions.
#
#################################################################

{#- ################################## #}
{#- # Required parameters from pillar  #}
{#- ################################## #}

{%- set repoRoot = pillar['splunk']['repo_uri_host'] %}
{%- set repoRootPath = pillar['splunk']['repo_uri_root_path'] %}
{%- set repoConfigPath = pillar['splunk']['repo_uri_config_path'] %}
{%- set LogCfg = pillar['splunk']['log_config_file'] %}
{%- set LogCfg_hash = pillar['splunk']['log_config_hash_file'] %}
{%- set CltCfg = pillar['splunk']['client_config_file'] %}
{%- set CltCfg_hash = pillar['splunk']['client_config_hash_file'] %}
{%- set splunkPkgName = pillar['splunk']['package_name'] %}
{%- set splunkPkgHash = pillar['splunk']['package_hash_file'] %}

{#- ################################## #}
{#- # Optional parameters from pillar  #}
{#- ################################## #}

{#- Get the splunk root_dir from pillar, or default to #}
{#- `/opt/splunkforwarder` #}

{%- set splunkRoot = salt['pillar.get'](
    'splunk:install_root_dir',
    '/opt/splunkforwarder') %}

{#- ################################## #}
{# Internal variables                  #}
{#- ################################## #}

{%- set repoPkgPath = repoRoot ~ '/' ~ repoRootPath %}
{%- set repoCfgPath = repoPkgPath ~ '/' ~ repoConfigPath %}
{%- set pkgPath = repoPkgPath ~ '/' ~ splunkPkgName %}
{%- set splunkEtc = splunkRoot ~ '/etc' %}
{%- set splunkBin = splunkRoot ~ '/bin' %}
{%- set splunkLcl = splunkEtc ~ '/system/local' %}

# Install the Splunk client RPM
splunk_package:
  pkg.installed:
    - sources:
      - splunkforwarder: {{ pkgPath }}

# Install the client log config
splunk_LogCfg:
  file.managed:
    - name: {{ splunkLcl ~ '/' ~ LogCfg }}
    - source: {{ repoCfgPath ~ '/' ~ LogCfg }}
    - source_hash: {{ repoCfgPath ~ '/' ~ LogCfg_hash }}
    - user: root
    - group: root
    - mode: 0600
    - require:
      - pkg: splunk_package

# Install the client agent config
splunk_CltCfg:
  file.managed:
    - name: {{ splunkLcl ~ '/' ~ CltCfg }}
    - source: {{ repoCfgPath ~ '/' ~ CltCfg }}
    - source_hash: {{ repoCfgPath ~ '/' ~ CltCfg_hash }}
    - user: root
    - group: root
    - mode: 0600
    - require:
      - pkg: splunk_package

# Accept Splunk license (so it doesn't wait-on-input at first start)
splunk_acceptLicense:
  cmd.run:
    - name: '{{ splunkBin }}/splunk start --accept-license'
    - require:
      - file: splunk_LogCfg
      - file: splunk_CltCfg
    - unless: 'test -f {{ splunkEtc }}/auth/splunkweb/cert.pem'

# Set up Splunk agent boot-scripts
splunk_enableBoot:
  cmd.run:
    - name: '{{ splunkBin }}/splunk enable boot-start'
    - require:
      - cmd: splunk_acceptLicense
    - unless: 'test -f /etc/init.d/splunk'

# Ensure that service is enabled
splunk_svcEnabled:
  service.enabled:
    - name: 'splunk'
    - require:
      - cmd: splunk_enableBoot

# Ensure that service is running
splunk_svcRunning:
  service.running:
    - name: 'splunk'
    - require:
      - service: splunk_svcEnabled
