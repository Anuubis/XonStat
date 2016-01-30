// Colors assigned to the various weapons
var weaponColors = {
  "gt": "#00d8ff",
  "mg": "#ffff40",
  "sg": "#ff8100",
  "gl": "#027812",
  "rl": "#ff0000",
  "lg": "#ffffb0",
  "rg": "#14c513",
  "pg": "#c500ff",
  "hmg": "#cea500",
  "bfg": "#015aff",
  //"ng": "#666666",
  //"cg": "#bbbbbb",
  //"pm": "#ffaaee"
};

var columnInfo = buildColumnInfo();
var matchIds = [];

// support functions to allow toggling weapons on/off by clicking on the legend

function buildColumnInfo() {
  var columns = [0];
  var columnsMap = {};
  var series = [];
  var seriesMap = [];
  var weapons = (getCookie("weapons") || "").split(",");

  Object.keys(weaponColors).forEach(function(w, i) {
    seriesMap.push({ column: 1 + i * 2, roleColumns: [1 + i * 2 + 1], color: weaponColors[w], display: weapons.indexOf(w) >= 0, weapon: w });
  });

  for (var i = 0; i < seriesMap.length; i++) {
    var col = seriesMap[i].column;
    columnsMap[col] = i;
    // set the default series option
    series[i] = { color: seriesMap[i].color, backupColor: seriesMap[i].color, weapon: seriesMap[i].weapon };
    if (seriesMap[i].display) {
      // if the column is the domain column or in the default list, display the series
      columns.push(col);
    }
    else {
      // otherwise, hide it
      columns.push({
        label: seriesMap[i].weapon.toUpperCase(),
        type: "number",
        sourceColumn: col,
        calc: function() { return null; }
      });
      series[i].color = '#444';
    }
    for (var j = 0; j < seriesMap[i].roleColumns.length; j++)
      columns.push(seriesMap[i].roleColumns[j]);
  }

  return { columns: columns, columnsMap: columnsMap, series: series }
}

function showHideSeries(chart, data, col) {
  var columns = columnInfo.columns;
  var columnsMap = columnInfo.columnsMap;
  var series = columnInfo.series;

  if (typeof(columns[col]) == 'number') {
    var src = columns[col];

    // hide the data series
    columns[col] = {
      label: data.getColumnLabel(src),
      type: data.getColumnType(src),
      sourceColumn: src,
      calc: function() { return null; }
    };

    // grey out the legend entry
    series[columnsMap[src]].color = '#444';
  }
  else {
    var src = columns[col].sourceColumn;

    // show the data series
    columns[col] = src;
    series[columnsMap[src]].color = series[columnsMap[src]].backupColor;
  }
  var view = chart.getView() || {};
  view.columns = columns;
  chart.setView(view);
  chart.draw();

  var weapons = getCookie("weapons").split(",");
  var w = series[columnsMap[src]].weapon;
  var idx = weapons.indexOf(w);
  if (idx >= 0)
    weapons.splice(idx, 1);
  else
    weapons.push(w);
  setCookie("weapons", weapons.join(","));
}


// Flatten the existing weaponstats JSON requests to ease indexing
function flatten(weaponData) {
  var flattened = {}

  // each game is a key entry...
  weaponData.games.forEach(function (e, i) { flattened[e] = {}; });

  // ... with indexes by weapon_cd
  weaponData.weapon_stats.forEach(function (e, i) {
    var game = flattened[e.game_id];
    if (game != undefined)
      game[e.weapon_cd] = e;
  });

  return flattened;
}



function accuracyValue(gameWeaponStats, weapon) {
  if (gameWeaponStats[weapon] == undefined) {
    return null;
  }
  var ws = gameWeaponStats[weapon];
  var minShots = "gl,rl,rg".indexOf(weapon) < 0 ? 10 : 4;
  var pct = ws.fired < minShots ? Number.NaN : Math.round((ws.hit / ws.fired) * 100);

  return pct;
}

function accuracyTooltip(weapon, pct, averages, gameWeaponStats) {
  if (pct == null) {
    return null;
  }

  var ws = gameWeaponStats[weapon];
  var tt = weapon.toUpperCase() + ": " + pct.toString() + "% [" + ws.hit + "/" + ws.fired + "]";
  if (averages[weapon] != undefined) {
    return tt + " (" + averages[weapon].toString() + "% average)";
  }

  return tt;
}

function drawAccuracyChart(weaponData) {
  matchIds = [];
  var data = new google.visualization.DataTable();
  data.addColumn('string', 'X');
  Object.keys(weaponColors).forEach(function(w, i) {
    data.addColumn('number', w.toUpperCase());
    data.addColumn({ type: 'string', role: 'tooltip' });
  });

  var flattened = flatten(weaponData);
  var nr = Object.keys(weaponData.games).length;
  for (i in weaponData.games) {
    var game_id = weaponData.games[i];
    var row = [(nr--).toString()];
    var ws = flattened[game_id];
    matchIds.push(game_id);
    for (w in weaponColors) {
      var acc = accuracyValue(ws, w);
      var tt = accuracyTooltip(w, acc, weaponData.averages, ws);
      row.push(acc);
      row.push(tt);
    }
    data.addRow(row);
  }
  matchIds.reverse();

  var options = getPercentageOptions(false);
  options.lineWidth = 2;
  options.series = columnInfo.series;
  var chart = new google.visualization.ChartWrapper({ chartType: 'LineChart', containerId: 'chartArea', dataTable: data, options: options, view: { columns: columnInfo.columns } });


  // a click on a point sends you to that games' page
  var accuracySelectHandler = function (e) {
    var selection = chart.getChart().getSelection()[0];
    if (selection == null) return;
    if (selection.row == null) {
      if (selection.column)
        showHideSeries(chart, data, selection.column);
    }
    else {
      var game_id = matchIds[data.getFormattedValue(selection.row, 0) -1];
      window.location.href = "/game/" + game_id.toString();
    }
  };
  google.visualization.events.addListener(chart, 'select', accuracySelectHandler);

  chart.draw();
}

function getPercentageOptions(addGauntlet) {
  return {
    backgroundColor: { fill: 'transparent' },
    legend: {
      textStyle: { color: "#eee" },
      position: "top"
    },
    hAxis: {
      title: 'Games',
      //textPosition: 'none',
      titleTextStyle: { color: '#eee' },
      textStyle: { color: "#888" }
    },
    vAxis: {
      title: 'Percentage',
      titleTextStyle: { color: '#eee' },
      textStyle: { color: "#888" },
      minValue: 0,
      maxValue: 100,
      baselineColor: '#eee',
      gridlineColor: '#888',
      ticks: [20, 40, 60, 80, 100]
    },
    interpolateNulls: true
  };
}




function fragValue(weapon, gameWeaponStats) {
  if (gameWeaponStats[weapon] == undefined) {
    return null;
  }
  return gameWeaponStats[weapon].frags;
}

function fragTooltip(weapon, ws, pct) {
  if (pct == null) {
    return null;
  }
  if (!ws[weapon])
    return weapon.toUpperCase() + ": not used";
  var frags = ws[weapon].frags;
  return weapon.toUpperCase() + ": " + frags + (frags == 1 ? " kill" : " kills") + " (" + Math.round(pct).toString() + "%)";
}

function getFragOptions(addGauntlet) {
  return {
    backgroundColor: { fill: 'transparent' },
    legend: {
      textStyle: { color: "#eee" },
      position: "top"
    },
    hAxis: {
      title: 'Games',
      titleTextStyle: { color: '#eee' },
      textStyle: { color: "#888" }
    },
    vAxis: {
      title: 'Frags',
      titleTextStyle: { color: '#eee' },
      textStyle: { color: "#888" },
      minValue: 0,
      //maxValue: 100,
      baselineColor: '#eee',
      gridlineColor: '#888',
      //ticks: [20, 40, 60, 80, 100]
    },
    interpolateNulls: true
  };
}

function drawFragChart(weaponData, inPercent) {
  matchIds = [];
  var data = new google.visualization.DataTable();
  data.addColumn('string', 'X');
  Object.keys(weaponColors).forEach(function(w, i) {
    data.addColumn('number', w.toUpperCase());
    data.addColumn({ type: 'string', role: 'tooltip' });
  });

  var flattened = flatten(weaponData);

  var nr = Object.keys(weaponData.games).length;
  for (i in weaponData.games) {
    var game_id = weaponData.games[i];
    var row = [(nr--).toString()];
    var ws = flattened[game_id];

    matchIds.push(game_id);
    var totalFrags = 0;
    for (var w in ws) {
      var frags = parseInt(ws[w].frags) || 0;
      totalFrags += frags;
    }
    totalFrags /= 100.0;

    for (w in weaponColors) {
      var val = fragValue(w, ws);
      var pct = val / totalFrags;
      var tt = fragTooltip(w, ws, pct);
      row.push(inPercent ? pct : val);
      row.push(tt);
    }
    data.addRow(row);
  }
  matchIds.reverse();


  //var info = buildColumnInfo();
  var options = inPercent ? getPercentageOptions(true) : getFragOptions(true);
  options.legend.maxLines = 3;
  options.isStacked = true;
  options.series = columnInfo.series;
  var chart = new google.visualization.ChartWrapper({ chartType: 'ColumnChart', containerId: 'chartArea', dataTable: data, options: options, view: { columns: columnInfo.columns }  });


  // a click on a point sends you to that game's page
  var fragSelectHandler = function (e) {
    var selection = chart.getChart().getSelection()[0];
    if (selection == null) return;
    if (selection.row == null) {
      if (selection.column)
        showHideSeries(chart, data, selection.column);
    }
    else {
      var game_id = matchIds[data.getFormattedValue(selection.row, 0) - 1];
      window.location.href = "/game/" + game_id.toString();
    }
  };
  google.visualization.events.addListener(chart, 'select', fragSelectHandler);
  chart.draw();
}




function damageValue(weapon, gameWeaponStats) {
  if (gameWeaponStats[weapon] == undefined) {
    return null;
  }
  return gameWeaponStats[weapon].max;
}

function damageTooltip(weapon, ws, pct) {
  if (pct == null) {
    return null;
  }
  if (!ws[weapon])
    return weapon.toUpperCase() + ": not used";
  var dmg = ws[weapon].max;
  return weapon.toUpperCase() + ": " + dmg + " dealt (" + Math.round(pct).toString() + "%)";
}

function getDamageOptions(addGauntlet) {
  var series = {};
  var i = 0;
  for (var w in weaponColors)
    series[i++] = { color: weaponColors[w] };

  return {
    backgroundColor: { fill: 'transparent' },
    legend: {
      textStyle: { color: "#eee" },
      position: "top"
    },
    hAxis: {
      title: 'Games',
      titleTextStyle: { color: '#eee' },
      textStyle: { color: "#888" }
    },
    vAxis: {
      title: 'Damage dealt',
      titleTextStyle: { color: '#eee' },
      textStyle: { color: "#888" },
      minValue: 0,
      //maxValue: 100,
      baselineColor: '#eee',
      gridlineColor: '#888',
      //ticks: [20, 40, 60, 80, 100]
    },
    series: series,
    interpolateNulls: true
  };
}

function drawDamageChart(weaponData, inPercent) {
  matchIds = [];
  var data = new google.visualization.DataTable();
  data.addColumn('string', 'X');
  for (w in weaponColors) {
    data.addColumn('number', w.toUpperCase());
    data.addColumn({ type: 'string', role: 'tooltip' });
  }

  var flattened = flatten(weaponData);
  var nr = Object.keys(weaponData.games).length;
  for (i in weaponData.games) {
    var game_id = weaponData.games[i];
    var row = [(nr--).toString()];
    var ws = flattened[game_id];
    matchIds.push(game_id);

    var total = 0;
    for (var w in ws) {
      var dmg = parseInt(ws[w].max) || 0;
      total += dmg;
    }
    total /= 100.0;

    for (w in weaponColors) {
      var val = damageValue(w, ws);
      var pct = val / total;
      var tt = damageTooltip(w, ws, pct);
      row.push(inPercent ? pct : val);
      row.push(tt);
    }
    data.addRow(row);
  }
  matchIds.reverse();

  var options = inPercent ? getPercentageOptions(true) : getDamageOptions(true);
  options.legend.maxLines = 3;
  options.isStacked = true;
  options.series = columnInfo.series;
  var chart = new google.visualization.ChartWrapper({ chartType: 'ColumnChart', containerId: 'chartArea', dataTable: data, options: options, view: { columns: columnInfo.columns }  });

  // a click on a point sends you to that game's page
  var damageSelectHandler = function (e) {
    var selection = chart.getChart().getSelection()[0];
    if (selection == null) return;
    if (selection.rows == null) {
      if (selection.column)
        showHideSeries(chart, data, selection.column);
    }
    else {
      var game_id = matchIds[data.getFormattedValue(selection.row, 0) - 1];
      window.location.href = "/game/" + game_id.toString();
    }
  };
  google.visualization.events.addListener(chart, 'select', damageSelectHandler);
  chart.draw();
}

