local types = require "cassandra.types"
local utils = require "cassandra.utils.table"
local type = type

--- Defaults
-- @section defaults

-- Nil values are stubs for the sole purpose of documenting their availability.
local DEFAULTS = {
  -- shm = nil,
  -- prepared_shm = nil,
  -- contact_points = {},
  -- keyspace = nil,
  policies = {
    address_resolution = require "cassandra.policies.address_resolution",
    load_balancing = require("cassandra.policies.load_balancing").SharedRoundRobin,
    retry = require("cassandra.policies.retry"),
    reconnection = require("cassandra.policies.reconnection").SharedExponential(1000, 10 * 60 * 1000)
  },
  query_options = {
    consistency = types.consistencies.one,
    serial_consistency = types.consistencies.serial,
    page_size = 1000,
    paging_state = nil,
    auto_paging = false,
    prepare = false,
    retry_on_timeout = true
  },
  protocol_options = {
    default_port = 9042,
    max_schema_consensus_wait = 5000
  },
  socket_options = {
    connect_timeout = 1000,
    read_timeout = 2000
  },
  -- username = nil,
  -- password = nil,
  -- ssl_options = {
  --   key = nil,
  --   certificate = nil,
  --   ca = nil, -- stub
  --   verify = false
  -- }
}

local function parse_session(options, lvl)
  if options == nil then options = {} end
  utils.extend_table(DEFAULTS, options)

  if options.keyspace ~= nil and type(options.keyspace) ~= "string" then
    return nil, "keyspace must be a string"
  end

  if options.shm == nil then
    return nil, "shm is required for spawning a cluster/session"
  end

  if type(options.shm) ~= "string" then
    return nil, "shm must be a string"
  end

  if options.shm == "" then
    return nil, "shm must be a valid string"
  end

  if options.prepared_shm == nil then
    options.prepared_shm = options.shm
  end

  if type(options.prepared_shm) ~= "string" then
    return nil, "prepared_shm must be a string"
  end

  if options.prepared_shm == "" then
    return nil, "prepared_shm must be a valid string"
  end

  if type(options.protocol_options.default_port) ~= "number" then
    return nil, "protocol default_port must be a number"
  end

  if type(options.policies.address_resolution) ~= "function" then
    return nil, "address_resolution policy must be a function"
  end

  return options
end

local function parse_cluster(options)
  local err

  options, err = parse_session(options)
  if err then
    return nil, err
  end

  if options.contact_points == nil then
    return nil, "contact_points option is required"
  end

  if type(options.contact_points) ~= "table" then
    return nil, "contact_points must be a table"
  end

  if not utils.is_array(options.contact_points) then
    return nil, "contact_points must be an array (integer-indexed table)"
  end

  if #options.contact_points < 1 then
    return nil, "contact_points must contain at least one contact point"
  end

  options.keyspace = nil -- it makes no sense to use keyspace in this context

  return options
end

return {
  parse_cluster = parse_cluster,
  parse_session = parse_session
}
