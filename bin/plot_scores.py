#!/usr/bin/env python3
import argparse
import pandas as pd
import json
import plotly.graph_objects as go

def main():
    p = argparse.ArgumentParser(
        description="Plot GMWI2 scores as an interactive HTML bar chart with live filtering"
    )
    p.add_argument('-i','--input',  required=True,
                   help="TSV file with columns: sample, gmwi2_score")
    p.add_argument('-o','--output', default='gmwi2_scores_bar.html',
                   help="Output HTML filename")
    args = p.parse_args()

    # 1) Load data
    df = pd.read_csv(args.input, sep='\t')

    # 2) Colors by sign
    colors = df['gmwi2_score'].apply(lambda v: '#669bbc' if v >= 0 else '#c1121f')

    # 3) Build the figure
    fig = go.Figure(go.Bar(
        x=df['sample'],
        y=df['gmwi2_score'],
        marker={'color': colors}
    ))
    fig.update_layout(
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)',
        title='<b>GMWI2 Scores per Sample</b>',
        xaxis_title='<b>Sample</b>',
        yaxis_title='<b>GMWI2 Score</b>',
        margin=dict(l=50, r=20, t=60, b=50)
    )
    fig.update_xaxes(
        showline=True, linecolor='black', linewidth=1, side='bottom',
        showgrid=False, tickangle=-45
    )
    fig.update_yaxes(
        showline=True, linecolor='black', linewidth=1, side='left',
        zeroline=True, zerolinecolor='darkgrey', zerolinewidth=2,
        showgrid=True, gridcolor='lightgrey', gridwidth=1,
        tickmode='linear', dtick=1
    )

    # 4) Serialize figure JSON
    fig_json = fig.to_json()

    # 5) Write custom HTML with filter box + embedded plot
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>GMWI2 Scores</title>
  <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
  <style>
    body {{ background: transparent; font-family: sans-serif; }}
    #controls {{ margin-bottom: 10px; }}
    input {{ padding: 4px; font-size: 14px; }}
  </style>
</head>
<body>
  <div id="controls">
    Filter sample: <input type="text" id="sample-filter" placeholder="Type sample ID..." oninput="updatePlot()" />
  </div>
  <div id="plot"></div>
  <script>
    // load the Plotly figure
    var fig = {fig_json};
    Plotly.newPlot('plot', fig.data, fig.layout);

    // filtering function
    function updatePlot() {{
      var val = document.getElementById('sample-filter').value;
      var trace = fig.data[0];
      var x = [], y = [], color = [];
      for (var i=0; i<trace.x.length; i++) {{
        if (trace.x[i].toLowerCase().includes(val.toLowerCase())) {{
          x.push(trace.x[i]);
          y.push(trace.y[i]);
          color.push(trace.marker.color[i]);
        }}
      }}
      Plotly.react('plot',
        [{{
          x: x, y: y, type: 'bar',
          marker: {{ color: color }}
        }}],
        fig.layout
      );
    }}
  </script>
</body>
</html>
"""
    with open(args.output, 'w') as fo:
        fo.write(html)
    print(f"Wrote interactive plot to {args.output}")

if __name__ == "__main__":
    main()
