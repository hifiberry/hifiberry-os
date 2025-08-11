-- Output Mode & Balance Filter for WirePlumber (system mode)

local mode_matrices = {
  stereo = { {1.0, 0.0}, {0.0, 1.0} },
  mono   = { {0.5, 0.5}, {0.5, 0.5} },
  left   = { {1.0, 0.0}, {1.0, 0.0} },
  right  = { {0.0, 1.0}, {0.0, 1.0} }
}

local current_mode = "stereo"
local current_balance = 0.0
local filter_node = nil

local function compute_matrix()
  local mat = { {0.0, 0.0}, {0.0, 0.0} }
  local base = mode_matrices[current_mode]
  if current_mode == "stereo" then
    local bal = current_balance
    local lgain = 1 - math.max(bal, 0)
    local rgain = 1 - math.max(-bal, 0)
    mat[1][1] = lgain * base[1][1]
    mat[1][2] = lgain * base[1][2]
    mat[2][1] = rgain * base[2][1]
    mat[2][2] = rgain * base[2][2]
  else
    mat = base
  end
  return mat
end

local function apply_matrix()
  if not filter_node then return end
  filter_node:set_param("Props", "copy.matrix", compute_matrix())
end

local function insert_filter(sink)
  if filter_node then
    Core:remove_object(filter_node)
    filter_node = nil
  end
  if not sink then return end

  filter_node = Node("libpipewire-module-filter-chain", {
    ["node.name"] = "output-mode-filter",
    ["media.name"] = "Output Mode Filter",
    ["capture.props"] = {
      ["node.target"] = sink.properties["node.name"]
    },
    ["playback.props"] = {
      ["media.class"] = "Audio/Sink"
    },
    ["filter.graph"] = {
      nodes = {
        {
          type = "builtin",
          label = "copy",
          name = "channel-mix",
          config = {
            ["copy.inputs"] = 2,
            ["copy.outputs"] = 2,
            ["copy.matrix"] = compute_matrix()
          }
        }
      }
    }
  })
  Core:link(filter_node)
end

SimpleEventHook {
  name = "DefaultSinkChange",
  interests = {
    EventInterest {
      type = "node-default-change",
      event_type = "default-sink"
    }
  },
  execute = function(event)
    local sink = event:get_data("node")
    insert_filter(sink)
  end
}:register()

Service.export("output-mode-filter", {
  set_mode = function(_, mode)
    if mode_matrices[mode] then
      current_mode = mode
      apply_matrix()
      return true
    end
    return false
  end,
  set_balance = function(_, bal)
    if type(bal) == "number" and bal >= -1 and bal <= 1 then
      current_balance = bal
      apply_matrix()
      return true
    end
    return false
  end
})
