local config = require("oil.config")
local confirmation = require("oil.mutator.confirmation")
local test_util = require("tests.test_util")

local CREATE = { type = "create", entry_type = "file", url = "oil-test:///foo/a.txt" }
local MOVE_A = {
  type = "move",
  entry_type = "file",
  src_url = "oil-test:///foo/a.txt",
  dest_url = "oil-test:///foo/b.txt",
}
local MOVE_C = {
  type = "move",
  entry_type = "file",
  src_url = "oil-test:///foo/c.txt",
  dest_url = "oil-test:///foo/d.txt",
}
local DELETE = { type = "delete", entry_type = "file", url = "oil-test:///foo/e.txt" }

---@param opts oil.SetupOpts
local function setup(opts)
  require("oil").setup(vim.tbl_extend("force", {
    adapters = { ["oil-test://"] = "test" },
  }, opts))
end

---@return boolean
local function popup_open()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(winid).relative ~= "" then
      return true
    end
  end
  return false
end

---@param actions oil.Action[]
---@return boolean skipped
local function skips_popup(actions)
  local proceed
  confirmation.show(actions, nil, function(p)
    proceed = p
  end)
  vim.wait(100, function()
    return proceed ~= nil
  end)
  assert.are_not.equal(proceed == true, popup_open())
  return proceed == true
end

describe("confirmation", function()
  after_each(function()
    -- setup() only overwrites the keys it is given, so clear the option between tests
    config.skip_confirm_for_delete = nil
    test_util.reset_editor()
  end)

  describe("skip_confirm_for_delete = false", function()
    before_each(function()
      setup({ skip_confirm_for_delete = false })
    end)

    it("skips the popup when there are no deletes", function()
      assert.is_true(skips_popup({ CREATE, MOVE_A, MOVE_C }))
    end)

    it("shows the popup when there is a delete", function()
      assert.is_false(skips_popup({ CREATE, DELETE }))
    end)
  end)

  describe("skip_confirm_for_delete = true", function()
    it("skips the popup when there is a delete", function()
      setup({ skip_confirm_for_delete = true })
      assert.is_true(skips_popup({ CREATE, DELETE }))
    end)
  end)

  describe("skip_confirm_for_delete = nil", function()
    it("falls back to skip_confirm_for_simple_edits", function()
      setup({ skip_confirm_for_simple_edits = true })
      assert.is_nil(config.skip_confirm_for_delete)
      assert.is_false(skips_popup({ MOVE_A, MOVE_C }))
    end)
  end)
end)
