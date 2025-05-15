#!/usr/bin/env python3
import argparse
import pandas as pd
import plotly.graph_objects as go

def main():
    parser = argparse.ArgumentParser(
        description="Plot GMWI2 scores with comma-aware autocomplete, exclude, sort, and hover labels"
    )
    parser.add_argument('-i','--input', required=True,
                        help="TSV file with columns: sample, gmwi2_score")
    parser.add_argument('-o','--output', default='gmwi2_scores_bar.html',
                        help="Output HTML filename")
    args = parser.parse_args()

    # 1) Load data
    df      = pd.read_csv(args.input, sep='\t')
    samples = df['sample'].tolist()
    scores  = df['gmwi2_score'].tolist()
    base_colors = [('#0072B2' if v >= 0 else '#D55E00') for v in scores]

    # 2) Build base Plotly figure
    fig = go.Figure(go.Bar(
        x=samples, y=scores,
        marker={'color': base_colors},
        hoverinfo='none'
    ))
    fig.update_layout(
        autosize=True,
        paper_bgcolor='#f8f9fa',
        plot_bgcolor='#f8f9fa',
        xaxis_title='<b>Sample</b>',
        yaxis_title='<b>GMWI2 Score</b>',
        font=dict(color='black'),
        margin=dict(l=50, r=20, t=100, b=70),
        title=None,
        annotations=[dict(
            x=0, y=1.02, xref='paper', yref='paper',
            text='<b>GMWI2 Scores per Sample</b>',
            showarrow=False,
            font=dict(size=28, color='white'),
            align='left',
            bgcolor='#343a40',
            borderpad=8,
            xanchor='left', yanchor='bottom'
        )]
    )
    fig.update_xaxes(
        showline=True, linecolor='black', side='bottom',
        showgrid=False, tickangle=-45
    )
    fig.update_yaxes(
        showline=True, linecolor='black', side='left',
        zeroline=True, zerolinecolor='darkgrey', zerolinewidth=2,
        showgrid=True, gridcolor='lightgrey', dtick=1
    )

    # 3) Serialize to JSON
    fig_json = fig.to_json()

    # 4) Write HTML with all JS braces escaped
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <title>GMWI2 Scores</title>
  <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
  <style>
    body {{ margin:0; background:transparent; font-family:sans-serif }}
    #controls {{ padding:10px; }}
    .autocomplete {{ position: relative; display: inline-block; width: 200px; }}
    .autocomplete input {{ width:100%; box-sizing:border-box; padding:4px; }}
    #suggestions {{ position:absolute; top:100%; left:0; right:0;
      background:white; border:1px solid #ccc; max-height:150px; 
      overflow-y:auto; display:none; z-index:1000; }}
    .suggestion-item {{ padding:4px; cursor:pointer; }}
    .suggestion-item:hover {{ background:#eee; }}
    #controls select, #controls input[type=checkbox] {{
      margin-left:10px; vertical-align:middle; padding:4px;
    }}
    #plot {{ width:100%; height:calc(100vh - 70px); }}
  </style>
</head>
<body>
  <div id="controls">
    <div class="autocomplete">
      <label>Filter sample(s):</label><br/>
      <input type="text" id="sample-filter"
             placeholder="Type at least 4 chars…"
             oninput="updateSuggestions(); updatePlot()"/>
      <div id="suggestions"></div>
    </div>
    <label>Exclude Others:
      <input type="checkbox" id="exclude-toggle" onchange="updatePlot()"/>
    </label>
    <label>Sort by:
      <select id="sort-order" onchange="updatePlot()">
        <option value="orig">Original</option>
        <option value="asc">Ascending</option>
        <option value="desc">Descending</option>
      </select>
    </label>
  </div>
  <div id="plot"></div>
  <script>
    const fig     = {fig_json};
    const baseX   = fig.data[0].x.slice();
    const baseY   = fig.data[0].y.slice();
    const baseC   = fig.data[0].marker.color.slice();
    const baseAnn = Array.isArray(fig.layout.annotations) 
                  ? fig.layout.annotations.slice() : [];

    Plotly.newPlot('plot', fig.data, fig.layout, {{responsive:true}});
    const plotDiv = document.getElementById('plot');

    // hover labels (keep title)
    plotDiv.on('plotly_hover', evt => {{
      const pt    = evt.points[0];
      const idx   = pt.pointIndex;
      const yval  = pt.y.toFixed(1);
      const curC  = fig.data[0].marker.color[idx];
      const above = pt.y >= 0;
      const hoverAnn = {{
        x: pt.x, y: pt.y,
        text: '<b>' + yval + '</b>',
        xanchor: 'center',
        yanchor: above ? 'bottom' : 'top',
        showarrow: false,
        font: {{ size:14, color:curC }},
        yshift: above ? 10 : -10
      }};
      Plotly.relayout(plotDiv, {{ annotations: baseAnn.concat([ hoverAnn ]) }});
    }});
    plotDiv.on('plotly_unhover', () => {{
      Plotly.relayout(plotDiv, {{ annotations: baseAnn }});
    }});

    // comma-aware autocomplete
    function updateSuggestions() {{
      const inp = document.getElementById('sample-filter');
      const full = inp.value;
      const parts = full.split(',');
      const lastRaw = parts.pop();
      const prefix = parts.join(',') + (parts.length? ', ' : '');
      const term   = lastRaw.trim().toLowerCase();
      const box = document.getElementById('suggestions');
      box.innerHTML = '';
      if(term.length < 4) {{ box.style.display='none'; return; }}
      const matches = baseX.filter(s => s.toLowerCase().includes(term)).slice(0,10);
      matches.forEach(m => {{
        const i = m.toLowerCase().indexOf(term);
        const before = m.slice(0, i);
        const match  = m.slice(i, i + term.length);
        const after  = m.slice(i + term.length);
        const div = document.createElement('div');
        div.className = 'suggestion-item';
        div.innerHTML = `<b>${{before}}</b>${{match}}<b>${{after}}</b>`;
        div.onclick = () => {{
          inp.value = prefix + m;
          box.innerHTML = '';
          box.style.display = 'none';
          updatePlot();
        }};
        box.appendChild(div);
      }});
      box.style.display = matches.length? 'block':'none';
    }}

    // filter/exclude/sort & redraw
    function updatePlot() {{
      const txt   = document.getElementById('sample-filter').value.toLowerCase();
      const keys  = txt.split(',').map(s=>s.trim()).filter(s=>s);
      const excl  = document.getElementById('exclude-toggle').checked;
      const order = document.getElementById('sort-order').value;

      let x0=[], y0=[], c0=[];
      for(let i=0; i<baseX.length; i++) {{
        const name  = baseX[i].toLowerCase();
        const val   = baseY[i];
        const match = keys.length===0 || keys.some(k=>name.includes(k));
        if(excl) {{
          if(match) {{ x0.push(baseX[i]); y0.push(val); c0.push(baseC[i]); }}
        }} else {{
          x0.push(baseX[i]); y0.push(val);
          c0.push(match?baseC[i]:'lightgrey');
        }}
      }}

      let idxArr = x0.map((_,i)=>i);
      if(order==='asc')     idxArr.sort((a,b)=> y0[a]-y0[b]);
      else if(order==='desc') idxArr.sort((a,b)=> y0[b]-y0[a]);

      const sx = idxArr.map(i=>x0[i]),
            sy = idxArr.map(i=>y0[i]),
            sc = idxArr.map(i=>c0[i]);
      const newTrace = {{ x:sx, y:sy, type:'bar', marker:{{color:sc}}, hoverinfo:'none' }};
      fig.data = [ newTrace ];
      Plotly.react(plotDiv, fig.data, fig.layout, {{responsive:true}});
    }}
  </script>
</body>
</html>
"""
    with open(args.output, 'w') as fo:
        fo.write(html)

    print(f"Wrote comma-aware autocomplete plot to {args.output}")

if __name__=="__main__":
    main()
