#!/usr/bin/env python3
import argparse, json
import pandas as pd
import plotly.graph_objects as go

def main():
    p = argparse.ArgumentParser(
        description="Bar chart with hover‐tooltip marker‐map"
    )
    p.add_argument('-i','--input', required=True,
                   help="TSV: sample, gmwi2_score")
    p.add_argument('-s','--stats', required=True,
                   help="TSV: sample, species, user_abundance, db_median, db_mean")
    p.add_argument('-o','--output', default='gmwi2_scores_tooltip.html')
    args = p.parse_args()

    # load main scores
    df = pd.read_csv(args.input, sep='\t')
    samples = df['sample'].tolist()
    scores  = df['gmwi2_score'].tolist()
    colors  = [('#0072B2' if v>=0 else '#D55E00') for v in scores]

    # build bar figure
    bar = go.Figure(go.Bar(x=samples, y=scores, marker=dict(color=colors), hoverinfo='none'))
    bar.update_layout(
        paper_bgcolor='#f8f9fa', plot_bgcolor='#f8f9fa',
        xaxis_title='<b>Sample</b>', yaxis_title='<b>GMWI2 Score</b>',
        margin=dict(l=50,r=20,t=80,b=70),
        annotations=[dict(x=0,y=1.05, xref='paper', yref='paper',
                          text='<b>GMWI2 Scores per Sample</b>',
                          showarrow=False, font=dict(size=24,color='white'),
                          bgcolor='#343a40', borderpad=8, xanchor='left')]
    )
    bar.update_xaxes(showgrid=False, tickangle=-45, showline=True, linecolor='black')
    bar.update_yaxes(showgrid=True, gridcolor='lightgrey', zeroline=True,
                     zerolinecolor='darkgrey', zerolinewidth=2,
                     showline=True, linecolor='black', dtick=1)

    fig_json   = bar.to_json()

    # load stats
    df_stats   = pd.read_csv(args.stats, sep='\t')
    stats_json = json.dumps(df_stats.to_dict(orient='records'))

    html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"/>
  <title>GMWI2 Scores + Hover Tooltip</title>
  <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
  <style>
    body {{ margin:0; font-family:sans-serif; background:transparent }}
    #plot {{ width:100%; height:100vh; }}
    #tooltip {{
      position:absolute; display:none;
      width:300px; height:200px;
      background:white; border:1px solid #ccc;
      box-shadow: 2px 2px 6px rgba(0,0,0,0.2);
      z-index:1000;
    }}
  </style>
</head><body>
  <div id="plot"></div>
  <div id="tooltip"></div>
  <script>
    const fig = {fig_json};
    const statsData = {stats_json};
    Plotly.newPlot('plot', fig.data, fig.layout, {{responsive:true}});
    const plotDiv = document.getElementById('plot');
    const tipDiv  = document.getElementById('tooltip');

    plotDiv.on('plotly_hover', evt => {{
      const pt = evt.points[0];
      const samp = pt.x;
      const recs = statsData.filter(r => r.sample===samp);
      if(!recs.length) return;

      // prepare marker‐map traces
      const sp = recs.map(r=>r.species),
            md = recs.map(r=>r.db_median),
            mn = recs.map(r=>r.db_mean),
            us = recs.map(r=>r.user_abundance);

      const traceM = {{
        x: md, y: sp, mode:'markers',
        marker:{{symbol:'circle', size:8, color:'grey'}},
        showlegend:false, hoverinfo:'x+y'
      }};
      const traceN = {{
        x: mn, y: sp, mode:'markers',
        marker:{{symbol:'square', size:8, color:'grey'}},
        showlegend:false, hoverinfo:'x+y'
      }};
      const traceU = {{
        x: us, y: sp, mode:'markers',
        marker:{{symbol:'circle-open', size:8, line:{{width:2,color:'#0072B2'}}}},
        showlegend:false, hoverinfo:'x+y'
      }};
      const shapes = sp.map((s,i)=>({{
        type:'line', x0:md[i], x1:us[i], y0:s, y1:s,
        line:{{color:'lightgrey', width:1}}, xref:'x', yref:'y'
      }}));

      const layoutTip = {{
        margin:{{l:60,r:10,t:20,b:20}}, 
        height:200, width:300,
        paper_bgcolor:'white', plot_bgcolor:'white',
        xaxis:{{visible:true, title:'Abundance', zeroline:false}},
        yaxis:{{visible:true, autorange:'reversed', automargin:true}},
        shapes: shapes,
        title:{{text:`<b>${{samp}}</b>`, x:0.5}}
      }};

      // draw inside tooltip
      Plotly.react(tipDiv,[traceM,traceN,traceU],layoutTip,{{staticPlot:true}});

      // position tooltip near mouse
      const ex = evt.event.clientX, ey=evt.event.clientY;
      tipDiv.style.left = (ex+10) + 'px';
      tipDiv.style.top  = (ey+10) + 'px';
      tipDiv.style.display = 'block';
    }});

    plotDiv.on('plotly_unhover', () => {{
      tipDiv.style.display = 'none';
    }});
  </script>
</body></html>
"""

    with open(args.output,'w') as f:
        f.write(html)
    print("Wrote interactive tooltip dashboard to", args.output)

if __name__=='__main__':
    main()
