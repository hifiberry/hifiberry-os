-- 16-Biquad Filter Chain for WirePlumber (system mode)
-- Inserts after default sink (like the output-mode filter)
-- Default: all biquads = passthrough

local biquads = {}
for i = 1, 16 do
  table.insert(biquads, {
    type = "builtin",
    label = "biquad",
    name = string.format("biquad-%02d", i),
    config = {
      ["biquad.type"] = "off", -- can be "lowpass", "highpass", "peaking", etc.
      ["biquad.freq"] = 1000.0,
      ["biquad.q"] = 1.0,
      ["biquad.gain"] = 0.0
    }
  })
end

local filter_node = nil

local function insert_filter(sink)
  if filter_node then
    Core:remove_object(filter_node)
    filter_node = nil
  end
  if not sink then return end

  filter_node = Node("libpipewire-module-filter-chain", {
    ["node.name"] = "eq-16biquad",
    ["media.name"] = "EQ 16-Biquad",
    ["capture.props"] = {
      ["node.target"] = sink.properties["node.name"]
    },
    ["playback.props"] = {
      ["media.class"] = "Audio/Sink"
    },
    ["filter.graph"] = {
      nodes = biquads
    }
  })
  Core:link(filter_node)
end

SimpleEventHook {
  name = "DefaultSinkChange-EQ",
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

-- RPC to set parameters for a given biquad
Service.export("eq-16biquad", {
  set_biquad = function(_, idx, btype, freq, q, gain)
    if not filter_node then return false end
    if idx < 1 or idx > 16 then return false end
    local node_name = string.format("biquad-%02d", idx)
    filter_node:set_param("Props", {
      ["filter.graph.nodes." .. node_name .. ".config.biquad.type"] = btype,
      ["filter.graph.nodes." .. node_name .. ".config.biquad.freq"] = freq,
      ["filter.graph.nodes." .. node_name .. ".config.biquad.q"] = q,
      ["filter.graph.nodes." .. node_name .. ".config.biquad.gain"] = gain
    })
    return true
  end
})
