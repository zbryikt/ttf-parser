require! <[fs]>

# https://www.cnblogs.com/sjhrun2001/archive/2010/01/19/1651274.html
# https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6.html

Util = ->
  @buf = it
  @length = it.length
  @

Util.prototype = do
  buf: null
  pad: -> "0" * (2 - ("#it".length <? 2)) + it
  value: (i,len = 1, be = true) ->
    if be => for j from 0 til len => ret = (ret or 0) * 256 + @buf[i + j]
    else for j from len - 1 to 0 by -1 => ret = (ret or 0) * 256 + @buf[i + j]
    return ret
  ascii-at: (i) -> @ascii i, 1
  ascii: (i,c) -> [String.fromCharCode(@buf[j]) for j from i til i + c].join("")
  subbuf: (i, c) ->
    if !c => c = @buf.length - i
    ret = Buffer.allocUnsafe(c)
    @buf.slice(i, i + c).copy(ret)
    return ret
  subtil: (i, c) -> new Util @subbuf(i,c)
  data-at: (i) -> @data i, 1
  data: (i,c) -> @raw.substring(i,i + c)
  hex-at: (i) -> @hex i, 1
  hex: (i,c) ->
    [@pad(@buf[j].toString(\16).toUpperCase!) for j from i til i + c].join("")

buf = fs.read-file-sync '5.ttf'
u = new Util(buf)
dir = do
  snftversion: u.value 0, 4
  numTables: u.value 4, 2
  searchRange: u.value 6, 2
  entrySelector: u.value 8, 2
  rangeShift: u.value 10, 2
console.log dir

# required tables
#   cmap
#   glyf
# o head
#   hhea
#   hmtx
#   loca
# o maxp
#   name
# - post

parser = do
  head: (u, offset) -> 
    ret = do
      table: u.value offset, 4
      fontRevision: u.value offset + 4, 4
      checkSumAdjustment: u.value offset + 8, 4
      magicNumber: u.hex offset + 12, 4
      flags: u.value offset + 16, 2
      unitsPerEm: u.value offset + 18, 2
      created: u.value offset + 20, 8
      modified: u.value offset + 28, 8
      xMin: u.value offset + 36, 2
      yMin: u.value offset + 38, 2
      xMax: u.value offset + 40, 2
      yMax: u.value offset + 42, 2
      macStyle: u.value offset + 44, 2
      lowestRecPPEM: u.value offset + 46, 2
      fontDirctionHint: u.value offset + 48, 2
      indexToLocFormat: u.value offset + 50, 2
      glyphDataFormat: u.value offset + 52, 2
  maxp: (u, offset) ->
    ret = do
      version: u.value offset, 4
      numGlyphs: u.value offset + 4, 2
      maxPoints: u.value offset + 6, 2
      maxContours: u.value offset + 8, 2
      maxCompositePoints: u.value offset + 10, 2
      maxCompositeContours: u.value offset + 12, 2
      maxZones: u.value offset + 14, 2
      maxTwilightPoints   : u.value offset + 16, 2
      maxStorage: u.value offset + 18, 2
      maxFunctionDefs: u.value offset + 20, 2
      maxStackElements: u.value offset + 22, 2
      maxSizeOfInstructions: u.value offset + 24, 2
      maxComponentElements: u.value offset + 26, 2
      maxComponentDepth: u.value offset + 28, 2
  glyf: (u, offset) ->
    ret = do
      numberOfContours: u.value offset, 2
      xMin: u.value offset + 2, 2
      yMin: u.value offset + 4, 2
      xMax: u.value offset + 6, 2
      yMax: u.value offset + 8, 2
  hhea: (u, offset) ->
    ret = do
      version: u.value offset, 4
      ascent: u.value offset + 4, 2
      descent: u.value offset + 6, 2
      lineGap: u.value offset + 8, 2
      advanceWidthMax: u.value offset + 10, 2
      minLeftSideBearing: u.value offset + 12, 2
      minRightSideBearing: u.value offset + 14, 2
      xMaxExtent: u.value offset + 16, 2
      caretSlopeRise: u.value offset + 18, 2
      caretSlopeRun: u.value offset + 20, 2
      caretOffset: u.value offset + 22, 2
      reserved1: u.value offset + 24, 2
      reserved2: u.value offset + 26, 2
      reserved3: u.value offset + 28, 2
      reserved4: u.value offset + 30, 2
      metricDataFormat: u.value offset + 32, 2
      numOfLongHorMetrics: u.value offset + 34, 2
  hmtx: (u, offset, tables) ->
    num = tables.hhea.numOfLongHorMetrics
    ret = {}
    ret.hMetrics = [0 til num].map (d,i) -> do
      advanceWidth: u.value offset + i * 4, 2
      leftSideBearing: u.value offset + i * 4 + 2, 2
  name: (u, offset, tables, entry) ->
    ret = do
      format: u.value offset, 2
      count: u.value offset + 2, 2
      stringOffset: u.value offset + 4, 2
    ret.nameRecord = [0 til ret.count].map (d,i) ->
      r = do
        platformID: u.value offset + 6 + i * 12, 2
        platformSpecificID: u.value offset + 6 + i * 12 + 2, 2
        languageID: u.value offset + 6 + i * 12 + 4, 2
        nameID: u.value offset + 6 + i * 12 + 6, 2
        length: u.value offset + 6 + i * 12 + 8, 2
        offset: u.value offset + 6 + i * 12 + 10, 2
      r.name = u.ascii offset + 6 + ret.count * 12 + r.offset, r.length
      r
    #ret.name = u.ascii offset + 6 + ret.count * 12, entry.length - (12 * ret.count + 6)
    ret
  post: (u, offset) ->
    ret = do
      format: u.value offset + 0, 4
      italicAngle: u.value offset + 4, 4
      underlinePosition: u.value offset + 8, 2
      underlineThickness: u.value offset + 10, 2
      isFixedPitch: u.value offset + 12, 4
      minMemType42: u.value offset + 16, 4
      maxMemType42: u.value offset + 20, 4
      minMemType1: u.value offset + 24, 4
      maxMemType1: u.value offset + 28, 4
  cmap: (u, offset, tables, entry) ->
    ret = do
      version: u.value offset, 2
      numberSubtables: u.value offset + 2, 2
    ret.subtables = [0 til ret.numberSubtables].map (d,i) ->
      r = do
        platformID: u.value offset + 4 + i * 8, 2
        platformSpecificID: u.value offset + 4 + i * 8 + 2, 2
        offset: u.value offset + 4 + i * 8 + 4, 4
      format = u.value offset + r.offset, 2
      r.format = format
      if format == 0 =>
        r.data = do
          format: format
          length: u.value offset + r.offset + 2, 2
          language: u.value offset + r.offset + 4, 2
          glyphIndexArray: u.subbuf offset + r.offset + 6, 256
      else if format == 4 =>
        r.data = do
          format: u.value offset + r.offset + 0, 2
          length: u.value offset + r.offset + 2, 2
          language: u.value offset + r.offset + 4, 2
          segCount: u.value(offset + r.offset + 6, 2) / 2
          searchRange: u.value offset + r.offset + 8, 2
          entrySelector: u.value offset + r.offset + 10, 2
          rangeShift: u.value offset + r.offset + 12, 2
        r.endCode = [0 til r.data.segCount].map (d,i) -> u.value offset + r.offset + 14 + i * 2, 2
        r.startCode = [0 til r.data.segCount].map (d,i) ->
          u.value 1 * r.data.segCount * 2 + 2 + offset + r.offset + 14 + i * 2, 2
        r.idDelta = [0 til r.data.segCount].map (d,i) ->
          u.value 2 * r.data.segCount * 2 + 2 + offset + r.offset + 14 + i * 2, 2
        r.idRangeOffset = [0 til r.data.segCount].map (d,i) ->
          u.value 3 * r.data.segCount * 2 + 2 + offset + r.offset + 14 + i * 2, 2
        #UInt16	glyphIndexArray[variable]	Glyph index array

      r
    #TODO finish it
      
    return ret



tables = {}


for i from 0 til dir.numTables
  offset = 12 + i * 16
  entry = do
    tag: u.ascii offset, 4
    checkSum: u.value offset + 4, 4
    offset: u.value offset + 8, 4
    length: u.value offset + 12, 4
  console.log entry
  entry.buf = u.subbuf(entry.offset, entry.length)
  entry.util = new Util(entry.buf)
  if parser[entry.tag] =>
    ret = parser[entry.tag](entry.util, 0, tables, entry)
    tables[entry.tag] = ret
    console.log ret
