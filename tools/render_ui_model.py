"""Render recorded Lua mock geometry as HTML for off-client layout review, never a game screenshot."""
import argparse
import html
from pathlib import Path
from create_assets import png


def render(model, output):
    root = Path(__file__).resolve().parents[1]
    nodes = {}
    for row in model.read_text(encoding='utf-8').splitlines():
        parts = row.split('\t')
        if len(parts) not in (18, 22):
            raise ValueError('Unexpected mock geometry row')
        index, kind, parent, visible, width, height, anchor, relative, relative_point, x, y, text, texture, all_points, size, justify, color, scroll = parts[:18]
        alpha, vertex, coords, layer = parts[18:] if len(parts) == 22 else ('1', '1,1,1,1', '0,1,0,1', '')
        nodes[int(index)] = dict(kind=kind, parent=int(parent), visible=visible == '1', width=float(width), height=float(height),
                                anchor=anchor, relative=int(relative), relative_point=relative_point, x=float(x), y=float(y),
                                text=text, texture=texture, all=int(all_points), size=float(size), justify=justify,
                                color=[float(n) for n in color.split(',')], scroll=float(scroll), alpha=float(alpha),
                                vertex=[float(n) for n in vertex.split(',')], coords=[float(n) for n in coords.split(',')], layer=layer)
    root_id = next(i for i, node in nodes.items() if node['parent'] == 0 and node['width'] == 1280)
    output.parent.mkdir(parents=True, exist_ok=True)
    textures = output.parent / 'textures'; textures.mkdir(exist_ok=True)
    for source in (root / 'addon/LumenShift/Media').glob('*.tga'):
        data = source.read_bytes(); w = int.from_bytes(data[12:14], 'little'); h = int.from_bytes(data[14:16], 'little')
        rgba = bytearray(data[18:])
        for offset in range(0, len(rgba), 4):
            rgba[offset], rgba[offset + 2] = rgba[offset + 2], rgba[offset]
        png(textures / (source.stem + '.png'), bytes(rgba), w, h)
    def emit(index):
        n = nodes[index]
        if not n['visible']:
            return ''
        style = ['position:absolute', 'box-sizing:border-box', f'opacity:{n["alpha"]}']
        if index == root_id:
            style += ['left:0', 'top:0', 'width:1280px', 'height:800px']
        elif n['all']:
            style += ['inset:0']
        else:
            style += [f'width:{n["width"]}px']
            if n['kind'] != 'FontString':
                style += [f'height:{n["height"]}px']
            ref = n['relative_point'] or 'TOPLEFT'
            left = '100%' if 'RIGHT' in ref else '0%' if 'LEFT' in ref else '50%'
            top = '100%' if 'BOTTOM' in ref else '0%' if 'TOP' in ref else '50%'
            tx = '-100%' if 'RIGHT' in n['anchor'] else '0%' if 'LEFT' in n['anchor'] else '-50%'
            ty = '-100%' if 'BOTTOM' in n['anchor'] else '0%' if 'TOP' in n['anchor'] else '-50%'
            if not n['anchor']:
                left = top = tx = ty = '0%'
            parent_scroll = nodes[n['parent']]['scroll'] if n['parent'] in nodes else 0
            style += [f'left:calc({left} + {n["x"]}px)', f'top:calc({top} - {n["y"] + parent_scroll}px)', f'transform:translate({tx},{ty})']
        c = n['color']; rgba = f'rgba({c[0]*255:.0f},{c[1]*255:.0f},{c[2]*255:.0f},{c[3]})'
        content = ''
        if n['kind'] == 'Texture':
            if n['texture']:
                name = Path(n['texture']).stem
                left, right, top, bottom = n['coords']
                size = f'{100 / (right-left)}% {100 / (bottom-top)}%'
                position = f'{-left * n["width"] / (right-left)}px {-top * n["height"] / (bottom-top)}px'
                if name.startswith(('ui-', 'switch-')):
                    v = n['vertex']
                    style += [f'background:rgba({v[0]*255:.0f},{v[1]*255:.0f},{v[2]*255:.0f},{v[3]})',
                              f'mask:url(textures/{name}.png) {position}/{size} no-repeat']
                else:
                    style += [f'background:url(textures/{name}.png) {position}/{size} no-repeat']
            else:
                style += [f'background:{rgba}']
        if n['kind'] == 'ScrollFrame':
            style += ['overflow:hidden']
        if n['kind'] in ('FontString', 'EditBox'):
            style += [f"font:{n['size']}px/1.35 'Segoe UI',sans-serif", f'text-align:{n["justify"].lower()}',
                      f'color:{rgba}', 'overflow-wrap:break-word']
            content = html.escape(n['text']).replace('\\n', '<br>')
            if n['kind'] == 'EditBox':
                style += ['padding:4px 6px', 'z-index:1', 'white-space:pre', 'overflow:hidden']
                content = '<span style="position:relative;z-index:2">' + content + '</span>'
        children = [child for child, node in nodes.items() if node['parent'] == index]
        layers = {'BACKGROUND': 0, 'BORDER': 1, 'ARTWORK': 2, 'OVERLAY': 3}
        children.sort(key=lambda child: (nodes[child]['kind'] != 'Texture', layers.get(nodes[child]['layer'], 4), child))
        return '<div style="' + ';'.join(style) + '">' + ''.join(emit(child) for child in children) + content + '</div>'
    document = '<!doctype html><meta charset="utf-8"><meta name="darkreader-lock"><meta name="color-scheme" content="dark"><title>LumenShift off-client UI model</title>'
    document += '<body style="margin:0;background:#172331;overflow:hidden">' + emit(root_id)
    # Camera effects/controls intentionally have no UIParent so they survive Alt+Z.
    document += ''.join(emit(i) for i, n in nodes.items() if i != root_id and n['parent'] == 0)
    document += '<div style="position:absolute;bottom:7px;left:15px;color:#a9baca;font:12px Segoe UI">OFF-CLIENT LUA UI MODEL — layout review only, not a native game screenshot</div></body>'
    output.write_text(document, encoding='utf-8')
    print(output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('model', type=Path); parser.add_argument('output', type=Path)
    args = parser.parse_args(); render(args.model, args.output)
