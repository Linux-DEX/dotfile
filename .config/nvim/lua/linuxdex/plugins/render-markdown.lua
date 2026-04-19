require("render-markdown").setup({
	enabled = true,
	max_file_size = 10.0,
	debounce = 100,
	preset = "none",
	markdown_query = [[
        (section) @section

        (atx_heading [
            (atx_h1_marker)
            (atx_h2_marker)
            (atx_h3_marker)
            (atx_h4_marker)
            (atx_h5_marker)
            (atx_h6_marker)
        ] @heading)
        (setext_heading) @heading

        (thematic_break) @dash

        (fenced_code_block) @code

        [
            (list_marker_plus)
            (list_marker_minus)
            (list_marker_star)
        ] @list_marker

        (task_list_marker_unchecked) @checkbox_unchecked
        (task_list_marker_checked) @checkbox_checked

        (block_quote) @quote

        (pipe_table) @table
    ]],
	markdown_quote_query = [[
        [
            (block_quote_marker)
            (block_continuation)
        ] @quote_marker
    ]],
	inline_query = [[
        (code_span) @code

        (shortcut_link) @shortcut

        [
            (image)
            (email_autolink)
            (inline_link)
            (full_reference_link)
        ] @link
    ]],
	log_level = "error",
	file_types = { "markdown" },
	injections = {
		gitcommit = {
			enabled = true,
			query = [[
                ((message) @injection.content
                    (#set! injection.combined)
                    (#set! injection.include-children)
                    (#set! injection.language "markdown"))
            ]],
		},
	},
	render_modes = { "n", "c" },
	acknowledge_conflicts = false,
	anti_conceal = {
		enabled = true,
		above = 0,
		below = 0,
	},
	latex = {
		enabled = true,
		converter = "latex2text",
		highlight = "RenderMarkdownMath",
		top_pad = 0,
		bottom_pad = 0,
	},
	heading = {
		enabled = true,
		sign = true,
		position = "overlay",
		icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
		signs = { "󰫎 " },
		width = "full",
		left_pad = 0,
		right_pad = 0,
		min_width = 0,
		border = false,
		border_prefix = false,
		above = "▄",
		below = "▀",
		backgrounds = {
			"RenderMarkdownH1Bg",
			"RenderMarkdownH2Bg",
			"RenderMarkdownH3Bg",
			"RenderMarkdownH4Bg",
			"RenderMarkdownH5Bg",
			"RenderMarkdownH6Bg",
		},
		foregrounds = {
			"RenderMarkdownH1",
			"RenderMarkdownH2",
			"RenderMarkdownH3",
			"RenderMarkdownH4",
			"RenderMarkdownH5",
			"RenderMarkdownH6",
		},
	},
	code = {
		enabled = true,
		sign = true,
		style = "full",
		position = "left",
		language_pad = 0,
		disable_background = { "diff" },
		width = "full",
		left_pad = 0,
		right_pad = 0,
		min_width = 0,
		border = "thin",
		above = "▄",
		below = "▀",
		highlight = "RenderMarkdownCode",
		highlight_inline = "RenderMarkdownCodeInline",
	},
	dash = {
		enabled = true,
		icon = "─",
		width = "full",
		highlight = "RenderMarkdownDash",
	},
	bullet = {
		enabled = true,
		icons = { "●", "○", "◆", "◇" },
		left_pad = 0,
		right_pad = 0,
		highlight = "RenderMarkdownBullet",
	},
	checkbox = {
		enabled = true,
		position = "inline",
		unchecked = {
			icon = "󰄱 ",
			highlight = "RenderMarkdownUnchecked",
		},
		checked = {
			icon = "󰱒 ",
			highlight = "RenderMarkdownChecked",
		},
		custom = {
			todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
		},
	},
	quote = {
		enabled = true,
		icon = "▋",
		repeat_linebreak = false,
		highlight = "RenderMarkdownQuote",
	},
	pipe_table = {
		enabled = true,
		preset = "none",
		style = "full",
		cell = "padded",
		alignment_indicator = "━",
		border = {
			"┌", "┬", "┐",
			"├", "┼", "┤",
			"└", "┴", "┘",
			"│", "─",
		},
		head = "RenderMarkdownTableHead",
		row = "RenderMarkdownTableRow",
		filler = "RenderMarkdownTableFill",
	},
	callout = {
		note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
		tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
		important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
		warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
		caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
		abstract = { raw = "[!ABSTRACT]", rendered = "󰨸 Abstract", highlight = "RenderMarkdownInfo" },
		summary = { raw = "[!SUMMARY]", rendered = "󰨸 Summary", highlight = "RenderMarkdownInfo" },
		tldr = { raw = "[!TLDR]", rendered = "󰨸 Tldr", highlight = "RenderMarkdownInfo" },
		info = { raw = "[!INFO]", rendered = "󰋽 Info", highlight = "RenderMarkdownInfo" },
		todo = { raw = "[!TODO]", rendered = "󰗡 Todo", highlight = "RenderMarkdownInfo" },
		hint = { raw = "[!HINT]", rendered = "󰌶 Hint", highlight = "RenderMarkdownSuccess" },
		success = { raw = "[!SUCCESS]", rendered = "󰄬 Success", highlight = "RenderMarkdownSuccess" },
		check = { raw = "[!CHECK]", rendered = "󰄬 Check", highlight = "RenderMarkdownSuccess" },
		done = { raw = "[!DONE]", rendered = "󰄬 Done", highlight = "RenderMarkdownSuccess" },
		question = { raw = "[!QUESTION]", rendered = "󰘥 Question", highlight = "RenderMarkdownWarn" },
		help = { raw = "[!HELP]", rendered = "󰘥 Help", highlight = "RenderMarkdownWarn" },
		faq = { raw = "[!FAQ]", rendered = "󰘥 Faq", highlight = "RenderMarkdownWarn" },
		attention = { raw = "[!ATTENTION]", rendered = "󰀪 Attention", highlight = "RenderMarkdownWarn" },
		failure = { raw = "[!FAILURE]", rendered = "󰅖 Failure", highlight = "RenderMarkdownError" },
		fail = { raw = "[!FAIL]", rendered = "󰅖 Fail", highlight = "RenderMarkdownError" },
		missing = { raw = "[!MISSING]", rendered = "󰅖 Missing", highlight = "RenderMarkdownError" },
		danger = { raw = "[!DANGER]", rendered = "󱐌 Danger", highlight = "RenderMarkdownError" },
		error = { raw = "[!ERROR]", rendered = "󱐌 Error", highlight = "RenderMarkdownError" },
		bug = { raw = "[!BUG]", rendered = "󰨰 Bug", highlight = "RenderMarkdownError" },
		example = { raw = "[!EXAMPLE]", rendered = "󰉹 Example", highlight = "RenderMarkdownHint" },
		quote = { raw = "[!QUOTE]", rendered = "󱆨 Quote", highlight = "RenderMarkdownQuote" },
		cite = { raw = "[!CITE]", rendered = "󱆨 Cite", highlight = "RenderMarkdownQuote" },
	},
	link = {
		enabled = true,
		image = "󰥶 ",
		email = "󰀓 ",
		hyperlink = "󰌹 ",
		highlight = "RenderMarkdownLink",
		custom = {
			web = { pattern = "^http[s]?://", icon = "󰖟 ", highlight = "RenderMarkdownLink" },
		},
	},
	sign = {
		enabled = true,
		highlight = "RenderMarkdownSign",
	},
	indent = {
		enabled = false,
		per_level = 2,
	},
	win_options = {
		conceallevel = {
			default = vim.api.nvim_get_option_value("conceallevel", {}),
			rendered = 3,
		},
		concealcursor = {
			default = vim.api.nvim_get_option_value("concealcursor", {}),
			rendered = "",
		},
	},
	overrides = {
		buftype = {
			nofile = { sign = { enabled = false } },
		},
		filetype = {},
	},
	custom_handlers = {},
})
