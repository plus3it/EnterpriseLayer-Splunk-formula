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

{% set whereAmI = salt['grains.get']('deployment_env', '') %}

{% if whereAmI %}
notify_{{ whereAmI }}:
  cmd.run:
    - name: 'echo "This instance is in {{ whereAmI }}."'
    - cwd: '/root'
{% endif %}
