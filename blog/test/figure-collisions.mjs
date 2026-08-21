/**
 * Find text in the inline SVG figures that collides with something.
 *
 * The figures are set in JetBrains Mono, the same face as the rest of the page.
 * Measured in a browser against the figures themselves, its advance width is
 * 0.600 of the font size and its box is 1.31 tall, sitting 1.017 above the
 * baseline. Those three constants make a text box computable without a browser,
 * which is what lets this run as a test. Re-measure them if the face changes.
 */
const ADVANCE = 0.600;
const ASCENT = 1.017;
const HEIGHT = 1.31;
/** Overlaps smaller than this are touching rather than colliding. */
const SLACK = 1.2;
/** A stroke crossing more than this many units of a label obscures a glyph. */
const CROSSING = 9;
/**
 * Width times opacity, which is how much ink a stroke actually puts on the
 * page. A faint column separator comes to 0.25 and is a chart convention a
 * reader looks straight through. A connector or an arrow comes to 2 and strikes
 * the word out.
 */
const INK = 0.5;

/*
 * A shape hides text under it whether it does so with fill or with outline. A
 * node circle at 0.12 fill still draws a stroke straight through any glyph it
 * crosses, so checking the fill alone lets that case through, which is exactly
 * how the first draft of the topologies figure passed.
 */
const filledIn = (attrs) => {
  const fill = attr(attrs, 'fill');
  const fillOpacity = Number(attr(attrs, 'fill-opacity') ?? '1');
  return fill !== 'none' && fill !== null && fillOpacity >= 0.25;
};

const outlined = (attrs, inherited) => {
  const stroke = attr(attrs, 'stroke') ?? inherited.stroke;
  const strokeOpacity = Number(attr(attrs, 'stroke-opacity') ?? inherited.strokeOpacity ?? '1');
  return Boolean(stroke) && stroke !== 'none' && strokeOpacity >= 0.25;
};

const attr = (tag, name) => {
  const m = tag.match(new RegExp(`\\b${name}="([^"]*)"`));
  return m ? m[1] : null;
};

const decode = (s) =>
  s.replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>');

/** Walk an SVG, tracking font-size and fill-opacity inherited from groups. */
function parse(svg) {
  const texts = [];
  const rects = [];
  const lines = [];
  const stack = [{ fontSize: 16, anchor: 'start', strokeWidth: 1, stroke: null, strokeOpacity: 1 }];
  let order = 0;

  const token = /<(\/?)(g|text|rect|line|path|circle)\b([^>]*?)(\/?)>([^<]*)/g;
  let m;
  while ((m = token.exec(svg))) {
    const [, closing, name, attrs, selfClose, tail] = m;
    if (closing) {
      if (name === 'g') stack.pop();
      continue;
    }
    const inherited = stack[stack.length - 1];
    const fontSize = Number(attr(attrs, 'font-size')) || inherited.fontSize;
    const anchor = attr(attrs, 'text-anchor') || inherited.anchor;
    const strokeWidth = Number(attr(attrs, 'stroke-width')) || inherited.strokeWidth;
    const stroke = attr(attrs, 'stroke') ?? inherited.stroke;
    const strokeOpacity = Number(attr(attrs, 'stroke-opacity') ?? inherited.strokeOpacity);

    if (name === 'g' && !selfClose) {
      stack.push({ fontSize, anchor, strokeWidth, stroke, strokeOpacity });
    } else if (name === 'text') {
      const chars = decode(tail).trim().length;
      const w = chars * ADVANCE * fontSize;
      const x = Number(attr(attrs, 'x')) || 0;
      const y = Number(attr(attrs, 'y')) || 0;
      const left = anchor === 'middle' ? x - w / 2 : anchor === 'end' ? x - w : x;
      texts.push({
        order: order++,
        text: decode(tail).trim(),
        x: left, y: y - ASCENT * fontSize, w, h: HEIGHT * fontSize,
      });
    } else if (name === 'rect') {
      rects.push({
        order: order++,
        x: Number(attr(attrs, 'x')) || 0, y: Number(attr(attrs, 'y')) || 0,
        w: Number(attr(attrs, 'width')) || 0, h: Number(attr(attrs, 'height')) || 0,
        filled: filledIn(attrs),
        visible: filledIn(attrs) || outlined(attrs, inherited),
      });
    } else if (name === 'line') {
      lines.push({
        order: order++,
        x1: Number(attr(attrs, 'x1')), y1: Number(attr(attrs, 'y1')),
        x2: Number(attr(attrs, 'x2')), y2: Number(attr(attrs, 'y2')),
        width: strokeWidth,
        ink: strokeWidth * (Number.isFinite(strokeOpacity) ? strokeOpacity : 1),
      });
    } else if (name === 'path') {
      // Straight-run paths flatten to segments. Curves are left alone: a
      // bezier's control points are a poor guide to where the ink lands.
      const d = attr(attrs, 'd') || '';
      if (!/[CcSsQqTtAa]/.test(d)) {
        const width = strokeWidth;
        const ink = width * (Number.isFinite(strokeOpacity) ? strokeOpacity : 1);
        for (const seg of flatten(d)) lines.push({ order: order++, ...seg, width, ink });
      }
    } else if (name === 'circle') {
      const r = Number(attr(attrs, 'r')) || 0;
      rects.push({
        order: order++,
        x: (Number(attr(attrs, 'cx')) || 0) - r, y: (Number(attr(attrs, 'cy')) || 0) - r,
        w: r * 2, h: r * 2,
        label: true,
        filled: filledIn(attrs),
        visible: filledIn(attrs) || outlined(attrs, inherited),
      });
    }
  }
  return { texts, rects, lines };
}

/** Flatten the straight-line subset of a path's d attribute into segments. */
function flatten(d) {
  const out = [];
  const tokens = d.match(/[MmLlHhVvZz]|-?[\d.]+/g) || [];
  let [x, y, sx, sy] = [0, 0, 0, 0];
  let cmd = 'M';
  let i = 0;
  const num = () => Number(tokens[i++]);
  while (i < tokens.length) {
    if (/[MmLlHhVvZz]/.test(tokens[i])) cmd = tokens[i++];
    if (i >= tokens.length && !/[Zz]/.test(cmd)) break;
    const rel = cmd === cmd.toLowerCase();
    const [px, py] = [x, y];
    if (/[Mm]/.test(cmd)) {
      x = rel ? x + num() : num(); y = rel ? y + num() : num();
      [sx, sy] = [x, y];
      cmd = rel ? 'l' : 'L';
      continue;
    }
    if (/[Ll]/.test(cmd)) { x = rel ? x + num() : num(); y = rel ? y + num() : num(); }
    else if (/[Hh]/.test(cmd)) { x = rel ? x + num() : num(); }
    else if (/[Vv]/.test(cmd)) { y = rel ? y + num() : num(); }
    else if (/[Zz]/.test(cmd)) { [x, y] = [sx, sy]; i += 1; }
    out.push({ x1: px, y1: py, x2: x, y2: y });
  }
  return out;
}

const encloses = (shape, t) =>
  t.x >= shape.x - SLACK && t.x + t.w <= shape.x + shape.w + SLACK &&
  t.y >= shape.y - SLACK && t.y + t.h <= shape.y + shape.h + SLACK;

const overlap = (a, b) =>
  Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x) > SLACK &&
  Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y) > SLACK;

/** Cohen and Sutherland, enough to answer does this segment enter this box. */
function clipToBox(seg, box, pad) {
  const [xmin, ymin, xmax, ymax] = [box.x + pad, box.y + pad, box.x + box.w - pad, box.y + box.h - pad];
  if (xmax <= xmin || ymax <= ymin) return null;
  const code = (x, y) =>
    (x < xmin ? 1 : 0) | (x > xmax ? 2 : 0) | (y < ymin ? 4 : 0) | (y > ymax ? 8 : 0);
  let [x1, y1, x2, y2] = [seg.x1, seg.y1, seg.x2, seg.y2];
  let [c1, c2] = [code(x1, y1), code(x2, y2)];
  for (let guard = 0; guard < 8; guard += 1) {
    if (!(c1 | c2)) return Math.hypot(x2 - x1, y2 - y1);
    if (c1 & c2) return null;
    const out = c1 || c2;
    let x, y;
    if (out & 8) { x = x1 + ((x2 - x1) * (ymax - y1)) / (y2 - y1); y = ymax; }
    else if (out & 4) { x = x1 + ((x2 - x1) * (ymin - y1)) / (y2 - y1); y = ymin; }
    else if (out & 2) { y = y1 + ((y2 - y1) * (xmax - x1)) / (x2 - x1); x = xmax; }
    else { y = y1 + ((y2 - y1) * (xmin - x1)) / (x2 - x1); x = xmin; }
    if (out === c1) { [x1, y1] = [x, y]; c1 = code(x1, y1); } else { [x2, y2] = [x, y]; c2 = code(x2, y2); }
  }
  return null;
}

export function findCollisions(source, label) {
  const found = [];
  for (const [i, svg] of [...source.matchAll(/<svg[\s\S]*?<\/svg>/g)].entries()) {
    const box = svg[0].match(/viewBox="0 0 (\d+(?:\.\d+)?) (\d+(?:\.\d+)?)"/);
    const [vw, vh] = [Number(box[1]), Number(box[2])];
    const { texts, rects, lines } = parse(svg[0]);
    const where = `${label}#${i + 1}`;

    for (const t of texts) {
      if (t.x < -SLACK || t.x + t.w > vw + SLACK || t.y < -SLACK || t.y + t.h > vh + SLACK) {
        found.push(`${where} runs outside the viewBox: "${t.text}"`);
      }
    }
    for (let a = 0; a < texts.length; a += 1) {
      for (let b = a + 1; b < texts.length; b += 1) {
        if (overlap(texts[a], texts[b])) {
          found.push(`${where} text over text: "${texts[a].text}" / "${texts[b].text}"`);
        }
      }
    }
    for (const t of texts) {
      for (const l of lines) {
        // A line drawn under text still shows through, so order does not matter.
        // Two things obscure a glyph: a stroke thick enough to swallow it, and
        // a thin one running lengthwise through the words like a strikethrough.
        // A hairline gridline crossing a label is neither, and is left alone.
        const inside = clipToBox(l, t, Math.max(1, l.width / 2));
        if (inside === null) continue;
        // Unless something opaque was painted between the two. A label sitting
        // on a plate is a chart convention and the line genuinely passes behind
        // it, so the crossing a reader sees is nothing at all.
        const plated = rects.some(
          (r) => r.filled && r.order > l.order && r.order < t.order && encloses(r, t)
        );
        if (plated) continue;
        if (l.width >= 2.5) {
          found.push(`${where} a ${l.width} unit stroke runs under "${t.text}"`);
        } else if (inside > t.w / 2) {
          found.push(`${where} a line runs lengthwise through "${t.text}"`);
        } else if (inside > CROSSING && (l.ink ?? l.width) >= INK) {
          // A thin line crossing a long label fails the lengthwise test and
          // still strikes out several characters, which is what a reader sees
          // and what the browser-measured audit kept finding. One glyph is
          // 0.6 of the font size wide, so a run longer than about a character
          // and a half is covering something.
          found.push(`${where} a line crosses "${t.text}"`);
        }
      }
      for (const r of rects) {
        if (!r.visible || !overlap(t, r)) continue;
        // A filled shape drawn after the text paints over it. An outline drawn
        // after it does not: a ring around a word is a highlight, and gets
        // judged by the straddle rule below like any other edge.
        if (r.filled && r.order > t.order) {
          found.push(`${where} text painted over by a later shape: "${t.text}"`);
          continue;
        }
        // Drawn before the text. Enclosing it is the ordinary case, a panel
        // holding its own title or a node holding its own name. Straddling its
        // edge is not: the outline runs through the glyphs.
        if (encloses(r, t)) continue;
        // A straddled edge that a later shape paints over is not visible. That
        // is how a badge overlapping the top of a box is drawn, and it reads as
        // a tab rather than as a collision.
        const covered = rects.some((e) => e.order > r.order && e.filled && encloses(e, t));
        if (!covered) {
          found.push(`${where} text straddles the edge of a shape: "${t.text}"`);
        }
      }
    }
  }
  return found;
}
