# Parse settings from settings.json ...
{debug,strict,chunkSize,integrityCheck,throttle} = Meteor.settings

@debug            = debug or true
@strict           = strict or false
@chunkSize        = parseInt(chunkSize) or 272144
@integrityCheck   = integrityCheck or false
@throttle         = throttle or false
