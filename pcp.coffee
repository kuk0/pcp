match = (s, t) -> s.slice(0, t.length) == t.slice(0, s.length)

WP = '\u2659' # white pawn ♙
BP = '\u265F' # black pawn ♟
PR = '<span class="rvec">' + WP + '</span>' # right
PL = '<span class="lvec">' + WP + '</span>' # left
WPA = '<span class="rvec a">' + WP + '</span>' # right
WPB = '<span class="rvec b">' + WP + '</span>' # right

class ParallelRows
    constructor: (div, max) ->
        @div = div
        @max = max # max number of items in one row
        @r = [0, 1] # top/bottom row
        @c = [0, 0] # top/bottom column
        @rows = [] # html elements
        @_newRows()

    _newRows: () ->
        t = $('<div class="top-row" />')
        b = $('<div class="bot-row" />')
        @rows.push(t, b)
        @div.append(t, b)

    _appendItem: (item, where) ->
        @rows[@r[where]].append(item)
        if ++@c[where] >= @max
            @c[where] = 0
            @r[where] += 2
            if @r[where] >= @rows.length
                @_newRows()

    append: (top, bot) ->
        @_appendItem(item, 0) for item in top
        @_appendItem(item, 1) for item in bot

class Pcp
    constructor: (spec) ->
        {@id, @tiles} = spec
        @title = spec.title or ""
        @text = spec.text or ""
        @map = spec.map or {}  # we can map symbols into more complicated symbols (unicode, img,...)
        @start = spec.start
        if !(@start?) or @start < 0 or @start > @tiles.length
            @start = -1
        @seq = []
        @soln = spec.soln or []
        @stopper = spec.stopper
        @ts = "" # top string
        @bs = "" # bottom string

    mapstr: (s) ->
        M = @map
        ((if c of M then M[c] else c) for c in s).join('')

    undo: ->
        len = @seq.length
        if len > 1 or (len == 1 and @start == -1)
            i = @seq.pop()
            @ts = @ts.slice(0, -@tiles[i][1].length)
            @bs = @bs.slice(0, -@tiles[i][2].length)
            @top.find("span.soln:last").remove()
            @bot.find("span.soln:last").remove()
        @possible()

    restart: ->
        @top.empty()
        @bot.empty()
        @seq = []
        @ts = ""
        @bs = ""
        @len = 0
        if @start != -1
            @append @start
        @possible()

    hint: ->
        if @seq.length >= @soln.length
            return
        @append(@soln[@seq.length])

    hint2: ->
        n = @seq.length
        if n >= @soln.length
            return
        while not (@soln[n] in @stopper)
            @append @soln[n]
            n++
        @append @soln[n]
        n++

    append: (i) ->
        t = @tiles[i][1]
        b = @tiles[i][2]
        if match(@ts + t, @bs + b)
            # @hide
            @ts += t
            @bs += b
            #@pr.append(@mtiles[i][0], @mtiles[i][1])
            @top.append(@mtiles[i][0])
            @bot.append(@mtiles[i][1])
            sum = 0
            # @top.children().each(() -> sum += $(@).outerWidth())
            #`@top.children().each(function () { sum += $(this).outerWidth() })`
            # @top.scrollLeft(sum)
            # @bot.scrollLeft(sum)
            @seq.push(i)
            if @ts.length == @bs.length
                alert('Congratulations, you found a solution of length ' + @seq.length + '.')  # + ".\n" + @seq)
        else
            alert('Mismatch')
        @possible()

    possible: ->
        for t, i in @tiles
            if match(@ts + t[1], @bs + t[2])
                $('#' + @id + '-' + i).removeAttr("disabled")
            else
                $('#' + @id + '-' + i).attr("disabled", true)

    create: ->
        n = @tiles.length
        MAX = 10  # max number of tiles in a row

        # INIT (MAP TILES)
        @mtiles = []  # maped tiles - top and bottom
        for t in @tiles
            @mtiles.push([ #[@mapstr(t[1]), @mapstr(t[2])
                "<span class='soln' style='background-color: " + t[3] + "'>" + @mapstr(t[1]) + "</span>",
                "<span class='soln' style='background-color: " + t[3] + "'>" + @mapstr(t[2]) + "</span>"
            ])

        e = $("#" + @id)
        e.append("<h3>#{@title}</h3>")
        # TITLE & TEXT
        if @text != ""
            e.append("<p>#{@text}</p>")

        div = $('<div style=\"overflow: auto;\"></div>')
        input = $('<div></div>') # style=\"width:250px; float: left;\"

        # INPUT TILES
        table = $("<table border='0' />")
        for r in [0 ... n/MAX] by 1
            # buttons
            row_buttons = $("<tr />")
            # corresponding tiles
            row_tiles = $("<tr class='input-tiles' />")
            for i in [MAX * r ... Math.min(MAX * (r + 1), n)] by 1
              do (i) =>
                row_buttons.append( $("<td class='dnamecell' />").append(
                     $("<input type='button' class='dname' id='#{@id}-#{i}' value='#{@tiles[i][0]}'>")
                        .click(() => @append(i))
                )) # onMouseOver='#{@id}.show(#{i});' onMouseOut='#{@id}.hide();'
                row_tiles.append("""
                    <td>
                        <table class='input-tiles' style='background-color: #{@tiles[i][3]}'>
                            <tr><td class='input-tile'>#{if @tiles[i][1] then @mtiles[i][0] else '&nbsp;'}</td></tr>
                            <tr><td class='input-tile'>#{if @tiles[i][2] then @mtiles[i][1] else '&nbsp;'}</td></tr>
                        </table>
                    </td>
                """)
            table.append(row_buttons, row_tiles, "<tr class='spacer'></tr>")

        # UNDO & RESTART & HINT
        buttons = $('<div/>')
        $('<input type="button" value="undo">').click(() => @undo()).appendTo(buttons)
        $('<input type="button" value="restart">').click(() => @restart()).appendTo(buttons)
        $('<input type="button" value="hint">').click(() => @hint()).appendTo(buttons)
        if @stopper?
            $('<input type="button" value="hint++">').click(() => @hint2()).appendTo(buttons)

        # AREA FOR SOLUTION   # width: 500px;
        #@sol = $("""
        #    <div class="sol" style="float: left;">
        #    </div>
        #""")
        #@pr = new ParallelRows(@sol, 5)
        sol = $("""
            <div class="sol" style="float: left;">
                <table border="0">
                    <tr>
                        <td align="right" width="65px"><i>top&nbsp= </i></td>
                        <td><div class="top bmono"></div></td>
                    </tr><tr>
                        <td align="right" width="65px"><i>bottom&nbsp;= </i></td>
                        <td><div class="bottom bmono"></div></td>
                    </tr>
                </table>
            </div>
        """)
        # INIT (TOP & BOTTOM)
        @top = sol.find(".top")
        @bot = sol.find(".bottom")

        input.append(table, buttons)
        div.append(input, sol)
        e.append(div)

        @restart()
        #<!--input type="button" onClick="answer(\"id\", "+a+");" value="answer"-->
