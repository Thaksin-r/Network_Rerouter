import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const NetworkRerouterApp());

const Color ink = Color(0xFF0A1020);
const Color panel = Color(0xFF111A2D);
const Color panel2 = Color(0xFF172238);
const Color lineColor = Color(0xFF2B3953);
const Color cyan = Color(0xFF5DE1E6);
const Color green = Color(0xFF54D6A0);
const Color orange = Color(0xFFFFB86B);
const Color red = Color(0xFFFF6B7A);
const Color purple = Color(0xFFB6A0FF);

class NetworkRerouterApp extends StatelessWidget {
  const NetworkRerouterApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'NetPilot | Network Rerouter',
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(primary: cyan, surface: panel),
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ink,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lineColor),
        ),
      ),
    ),
    home: const NetworkDashboard(),
  );
}

class NetNode {
  NetNode({
    required this.id,
    required this.name,
    required this.kind,
    required this.pos,
    this.up = true,
  });
  final String id;
  String name;
  String kind;
  Offset pos;
  bool up;
  int lastHello = 0;
}

class NetLink {
  NetLink({
    required this.id,
    required this.a,
    required this.b,
    this.capacity = 100,
    this.cost = 10,
    this.delay = 5,
    this.loss = 0,
    this.up = true,
  });
  final String id;
  String a, b;
  double capacity, cost, delay, loss;
  bool up;
  double used = 0;
}

class NetFlow {
  NetFlow({
    required this.id,
    required this.name,
    required this.source,
    required this.destination,
    this.demand = 18,
    this.priority = 'Normal',
  });
  final String id;
  String name, source, destination, priority;
  double demand;
  double delivered = 0, latency = 0, loss = 0;
  List<String> path = [];
}

class NetworkDashboard extends StatefulWidget {
  const NetworkDashboard({super.key});
  @override
  State<NetworkDashboard> createState() => _NetworkDashboardState();
}

class _NetworkDashboardState extends State<NetworkDashboard> {
  final List<NetNode> nodes = [];
  final List<NetLink> links = [];
  final List<NetFlow> flows = [];
  final List<String> logs = [];
  final List<double> throughputHistory = [
    42,
    45,
    44,
    49,
    47,
    52,
    50,
    56,
    54,
    58,
    55,
    61,
  ];
  final List<double> lossHistory = [
    1.4,
    1.2,
    1.3,
    1.1,
    1.5,
    1.0,
    1.2,
    .9,
    1.1,
    .8,
    .9,
    .7,
  ];
  Timer? timer;
  int tick = 0;
  int idSeq = 1;
  bool running = false;
  bool failureLab = false;
  bool pendingConvergence = false;
  String protocol = 'OSPF SPF';
  String selectedNode = '';
  String selectedLink = '';
  String selectedFlow = '';
  String tool = 'select';
  String? connectFrom;
  double throughput = 58;
  double packetLoss = .8;
  double recoverySeconds = 1.2;
  double helloInterval = 2;
  double deadInterval = 6;
  double canvasScale = 1;

  @override
  void initState() {
    super.initState();
    _demo();
    _recalculate();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _demo() {
    nodes.addAll([
      NetNode(
        id: 'R1',
        name: 'Core Router',
        kind: 'router',
        pos: const Offset(.17, .50),
      ),
      NetNode(
        id: 'R2',
        name: 'Library Router',
        kind: 'router',
        pos: const Offset(.43, .24),
      ),
      NetNode(
        id: 'R3',
        name: 'Lab Router',
        kind: 'router',
        pos: const Offset(.44, .74),
      ),
      NetNode(
        id: 'R4',
        name: 'Hostel Router',
        kind: 'router',
        pos: const Offset(.69, .47),
      ),
      NetNode(
        id: 'PC1',
        name: 'Student PC',
        kind: 'pc',
        pos: const Offset(.87, .22),
      ),
      NetNode(
        id: 'S1',
        name: 'Learning Server',
        kind: 'server',
        pos: const Offset(.87, .75),
      ),
    ]);
    links.addAll([
      NetLink(id: 'L1', a: 'R1', b: 'R2', capacity: 100, cost: 10, delay: 4),
      NetLink(id: 'L2', a: 'R1', b: 'R3', capacity: 80, cost: 12, delay: 6),
      NetLink(id: 'L3', a: 'R2', b: 'R4', capacity: 70, cost: 10, delay: 5),
      NetLink(id: 'L4', a: 'R3', b: 'R4', capacity: 100, cost: 8, delay: 4),
      NetLink(id: 'L5', a: 'R2', b: 'PC1', capacity: 50, cost: 5, delay: 3),
      NetLink(id: 'L6', a: 'R4', b: 'S1', capacity: 60, cost: 6, delay: 4),
      NetLink(id: 'L7', a: 'R1', b: 'R4', capacity: 30, cost: 28, delay: 14),
    ]);
    flows.addAll([
      NetFlow(
        id: 'F1',
        name: 'E-learning video',
        source: 'PC1',
        destination: 'S1',
        demand: 24,
        priority: 'High',
      ),
      NetFlow(
        id: 'F2',
        name: 'Campus LMS',
        source: 'R3',
        destination: 'S1',
        demand: 16,
      ),
      NetFlow(
        id: 'F3',
        name: 'Voice / VoIP',
        source: 'R1',
        destination: 'PC1',
        demand: 8,
        priority: 'High',
      ),
    ]);
    idSeq = 8;
    _log('Topology loaded: 6 nodes, 7 links, 3 traffic flows.');
    _log('OSPF process started; Hello neighbor discovery enabled.');
    _log('All router adjacencies converged to Full state.');
  }

  NetNode? _node(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  NetLink? _link(String id) {
    for (final l in links) {
      if (l.id == id) return l;
    }
    return null;
  }

  void _log(String message) {
    final now = DateTime.now();
    logs.insert(
      0,
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}  $message',
    );
    if (logs.length > 80) logs.removeLast();
  }

  List<NetLink> _path(String source, String destination) {
    if (_node(source) == null ||
        _node(destination) == null ||
        !_node(source)!.up ||
        !_node(destination)!.up)
      return [];
    final dist = <String, double>{};
    final prevNode = <String, String>{};
    final prevLink = <String, NetLink>{};
    final visited = <String>{};
    for (final n in nodes) {
      dist[n.id] = double.infinity;
    }
    dist[source] = 0;
    while (visited.length < nodes.length) {
      String? current;
      var best = double.infinity;
      dist.forEach((id, d) {
        if (!visited.contains(id) && d < best) {
          current = id;
          best = d;
        }
      });
      if (current == null || best == double.infinity) break;
      if (current == destination) break;
      visited.add(current!);
      for (final l in links.where(
        (l) =>
            l.up &&
            (_node(l.a)?.up ?? false) &&
            (_node(l.b)?.up ?? false) &&
            (l.a == current || l.b == current),
      )) {
        final next = l.a == current ? l.b : l.a;
        final weight = protocol == 'Capacity-aware'
            ? l.cost + (l.used / math.max(1, l.capacity)) * 24 + l.loss * 0.8
            : l.cost;
        final candidate = best + weight;
        if (candidate < (dist[next] ?? double.infinity)) {
          dist[next] = candidate;
          prevNode[next] = current!;
          prevLink[next] = l;
        }
      }
    }
    if (source != destination && !prevNode.containsKey(destination)) return [];
    final result = <NetLink>[];
    var at = destination;
    while (at != source) {
      final l = prevLink[at];
      final p = prevNode[at];
      if (l == null || p == null) return [];
      result.insert(0, l);
      at = p;
    }
    return result;
  }

  void _recalculate() {
    for (final l in links) {
      l.used = 0;
    }
    var deliveredTotal = 0.0;
    var demandTotal = 0.0;
    var lossWeighted = 0.0;
    for (final f in flows) {
      f.path = _path(f.source, f.destination).map((l) => l.id).toList();
      demandTotal += f.demand;
      if (f.path.isEmpty) {
        f.delivered = 0;
        f.loss = 100;
        f.latency = 0;
        lossWeighted += f.demand * 100;
        continue;
      }
      var bottleneck = double.infinity, delay = 0.0, linkLoss = 0.0;
      for (final id in f.path) {
        final l = _link(id)!;
        bottleneck = math.min(bottleneck, l.capacity).toDouble();
        delay += l.delay;
        linkLoss = 100 - (100 - linkLoss) * (100 - l.loss) / 100;
      }
      f.delivered = math.min(f.demand, bottleneck).toDouble();
      f.loss = linkLoss;
      f.latency = delay;
      final weight = f.priority == 'High' ? 1.25 : 1.0;
      for (final id in f.path) {
        _link(id)!.used += f.delivered * weight;
      }
      deliveredTotal += f.delivered;
      lossWeighted += f.demand * f.loss;
    }
    for (final l in links) {
      if (l.used > l.capacity) l.used = l.capacity;
    }
    throughput = deliveredTotal;
    packetLoss = demandTotal == 0 ? 0 : lossWeighted / demandTotal;
    throughputHistory.add(throughput);
    lossHistory.add(packetLoss);
    if (throughputHistory.length > 24) throughputHistory.removeAt(0);
    if (lossHistory.length > 24) lossHistory.removeAt(0);
  }

  void _toggleRun() {
    if (running) {
      timer?.cancel();
      timer = null;
      setState(() {
        running = false;
      });
      _log('Simulation paused.');
      return;
    }
    setState(() {
      running = true;
    });
    _log('Live simulation running; traffic and Hello timers are ticking.');
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        tick++;
        for (final n in nodes.where((n) => n.kind == 'router' && n.up)) {
          n.lastHello = tick;
        }
        for (var i = 0; i < flows.length; i++) {
          final f = flows[i];
          final wave = math.sin((tick + i * 2) * .65) * .14;
          f.demand = (f.demand * (1 + wave)).clamp(2.0, 150.0).toDouble();
        }
        if (failureLab && tick % 13 == 0 && links.isNotEmpty) {
          final available = links.where((l) => l.up).toList();
          if (available.isNotEmpty)
            _failLink(available[tick % available.length].id, announce: false);
        }
        _recalculate();
      });
    });
  }

  void _failLink(String id, {bool announce = true}) {
    final l = _link(id);
    if (l == null) return;
    setState(() {
      l.up = false;
      pendingConvergence = true;
      selectedLink = id;
      _recalculate();
    });
    if (announce)
      _log('Link $id failed (${l.a} ↔ ${l.b}); neighbor adjacency lost.');
    _log('SPF recalculation scheduled after topology change.');
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        pendingConvergence = false;
        _recalculate();
        recoverySeconds = .9 + (math.Random().nextDouble() * .5);
      });
      _log(
        'OSPF SPF complete; routes updated. Recovery ${recoverySeconds.toStringAsFixed(1)} s.',
      );
    });
  }

  void _restoreLink(String id) {
    final l = _link(id);
    if (l == null) return;
    setState(() {
      l.up = true;
      _recalculate();
    });
    _log('Link $id restored. Hello packets exchanged; adjacency rebuilding.');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _recalculate();
      });
      _log('Adjacency Full; SPF routes refreshed.');
    });
  }

  void _failNode(String id) {
    final n = _node(id);
    if (n == null) return;
    setState(() {
      n.up = false;
      for (final l in links.where((l) => l.a == id || l.b == id)) {
        l.up = false;
      }
      _recalculate();
    });
    _log(
      '${n.name} ($id) is down. Neighbor Hellos will time out; routes withdrawn.',
    );
  }

  void _restoreNode(String id) {
    final n = _node(id);
    if (n == null) return;
    setState(() {
      n.up = true;
      for (final l in links.where((l) => l.a == id || l.b == id)) {
        l.up = true;
      }
      _recalculate();
    });
    _log(
      '${n.name} ($id) restored. Hello exchange and SPF convergence started.',
    );
  }

  Future<void> _addNodeDialog() async {
    final name = TextEditingController(text: 'New Router');
    String kind = 'router';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: panel,
          title: const Text('Add network node'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Node name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: kind,
                items: const [
                  DropdownMenuItem(value: 'router', child: Text('Router')),
                  DropdownMenuItem(value: 'pc', child: Text('Client / PC')),
                  DropdownMenuItem(value: 'server', child: Text('Server')),
                ],
                onChanged: (v) => setD(() => kind = v ?? 'router'),
                decoration: const InputDecoration(labelText: 'Node type'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, {'name': name.text.trim(), 'kind': kind}),
              child: const Text('Add node'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result['name']!.isEmpty) return;
    setState(() {
      final id = result['kind'] == 'router'
          ? 'R${idSeq++}'
          : result['kind'] == 'server'
          ? 'S${idSeq++}'
          : 'PC${idSeq++}';
      nodes.add(
        NetNode(
          id: id,
          name: result['name']!,
          kind: result['kind']!,
          pos: Offset(
            .25 + math.Random().nextDouble() * .5,
            .2 + math.Random().nextDouble() * .6,
          ),
        ),
      );
      selectedNode = id;
      selectedLink = '';
      selectedFlow = '';
    });
    _log(
      'Node ${result['name']} added. Add a link to connect it to the topology.',
    );
  }

  Future<void> _addLinkDialog() async {
    if (nodes.length < 2) return;
    String a = nodes.first.id, b = nodes.last.id;
    final cap = TextEditingController(text: '50');
    final cost = TextEditingController(text: '10');
    final delay = TextEditingController(text: '5');
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: panel,
          title: const Text('Add network link'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: a,
                  decoration: const InputDecoration(labelText: 'Endpoint A'),
                  items: nodes
                      .map(
                        (n) => DropdownMenuItem(
                          value: n.id,
                          child: Text('${n.id} · ${n.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setD(() => a = v ?? a),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: b,
                  decoration: const InputDecoration(labelText: 'Endpoint B'),
                  items: nodes
                      .map(
                        (n) => DropdownMenuItem(
                          value: n.id,
                          child: Text('${n.id} · ${n.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setD(() => b = v ?? b),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cap,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacity (Mbps)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cost,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'OSPF cost'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: delay,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Delay (ms)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'a': a,
                'b': b,
                'cap': cap.text,
                'cost': cost.text,
                'delay': delay.text,
              }),
              child: const Text('Create link'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    if (result['a'] == result['b']) {
      _snack('Choose two different endpoints.');
      return;
    }
    if (links.any(
      (l) =>
          (l.a == result['a'] && l.b == result['b']) ||
          (l.a == result['b'] && l.b == result['a']),
    )) {
      _snack('A link already exists between these nodes.');
      return;
    }
    setState(() {
      final id = 'L${idSeq++}';
      links.add(
        NetLink(
          id: id,
          a: result['a']!,
          b: result['b']!,
          capacity: double.tryParse(result['cap']!) ?? 50,
          cost: double.tryParse(result['cost']!) ?? 10,
          delay: double.tryParse(result['delay']!) ?? 5,
        ),
      );
      selectedLink = id;
      selectedNode = '';
      selectedFlow = '';
      _recalculate();
    });
    _log(
      'Link created between ${result['a']} and ${result['b']}. SPF routes refreshed.',
    );
  }

  Future<void> _addFlowDialog() async {
    if (nodes.length < 2) {
      _snack('Add at least two nodes first.');
      return;
    }
    String source = nodes.first.id, dest = nodes.last.id, priority = 'Normal';
    final name = TextEditingController(text: 'New traffic flow');
    final demand = TextEditingController(text: '12');
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: panel,
          title: const Text('Add traffic flow'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Flow name'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: source,
                  decoration: const InputDecoration(labelText: 'Source'),
                  items: nodes
                      .map(
                        (n) => DropdownMenuItem(
                          value: n.id,
                          child: Text('${n.id} · ${n.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setD(() => source = v ?? source),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: dest,
                  decoration: const InputDecoration(labelText: 'Destination'),
                  items: nodes
                      .map(
                        (n) => DropdownMenuItem(
                          value: n.id,
                          child: Text('${n.id} · ${n.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setD(() => dest = v ?? dest),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: demand,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Demand (Mbps)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'High', child: Text('High')),
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                  ],
                  onChanged: (v) => setD(() => priority = v ?? 'Normal'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'name': name.text.trim(),
                'source': source,
                'dest': dest,
                'demand': demand.text,
                'priority': priority,
              }),
              child: const Text('Add flow'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    if (result['source'] == result['dest']) {
      _snack('Source and destination must differ.');
      return;
    }
    setState(() {
      final id = 'F${idSeq++}';
      flows.add(
        NetFlow(
          id: id,
          name: result['name']!.isEmpty ? 'Traffic flow' : result['name']!,
          source: result['source']!,
          destination: result['dest']!,
          demand: double.tryParse(result['demand']!) ?? 12,
          priority: result['priority']!,
        ),
      );
      selectedFlow = id;
      selectedNode = '';
      selectedLink = '';
      _recalculate();
    });
    _log('Traffic flow added: ${result['source']} → ${result['dest']}.');
  }

  void _deleteSelected() {
    if (selectedNode.isNotEmpty) {
      final id = selectedNode;
      nodes.removeWhere((n) => n.id == id);
      links.removeWhere((l) => l.a == id || l.b == id);
      flows.removeWhere((f) => f.source == id || f.destination == id);
      selectedNode = '';
      _log('Node $id and dependent links/flows deleted.');
    } else if (selectedLink.isNotEmpty) {
      final id = selectedLink;
      links.removeWhere((l) => l.id == id);
      selectedLink = '';
      _log('Link $id deleted.');
    } else if (selectedFlow.isNotEmpty) {
      final id = selectedFlow;
      flows.removeWhere((f) => f.id == id);
      selectedFlow = '';
      _log('Flow $id deleted.');
    } else {
      _snack('Select a node, link, or flow first.');
      return;
    }
    setState(_recalculate);
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1100;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(compact),
            Expanded(
              child: compact
                  ? _mobileBody()
                  : Row(
                      children: [
                        SizedBox(width: 218, child: _sidebar()),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: _topWorkspace()),
                              SizedBox(height: 236, child: _bottomPanel()),
                            ],
                          ),
                        ),
                        SizedBox(width: 290, child: _inspector()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool compact) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color: panel,
      border: Border(bottom: BorderSide(color: lineColor)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cyan,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.hub_rounded, color: cyan),
        ),
        const SizedBox(width: 11),

        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NETPILOT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 15,
              ),
            ),
            Text(
              'NETWORK REROUTER LAB',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(width: 22),

        if (!compact) Container(width: 1, height: 30, color: lineColor),

        if (!compact) const SizedBox(width: 20),

        _statusDot(running ? green : orange),
        const SizedBox(width: 7),

        Text(
          running ? 'SIMULATION LIVE' : 'SIMULATION PAUSED',
          style: TextStyle(
            color: running ? green : orange,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),

        const Spacer(),

        if (!compact)
          Text(
            'TICK ${tick.toString().padLeft(4, '0')}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),

        const SizedBox(width: 15),

        OutlinedButton.icon(
          onPressed: _toggleRun,
          icon: Icon(
            running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 18,
          ),
          label: Text(running ? 'Pause' : 'Run simulation'),
          style: OutlinedButton.styleFrom(
            foregroundColor: running ? orange : cyan,
            side: BorderSide(color: (running ? orange : cyan).withOpacity(0.5)),
          ),
        ),

        const SizedBox(width: 8),

        IconButton(
          tooltip: 'Reset demo topology',
          onPressed: () {
            timer?.cancel();
            setState(() {
              running = false;
              nodes.clear();
              links.clear();
              flows.clear();
              logs.clear();
              tick = 0;
              selectedNode = '';
              selectedLink = '';
              selectedFlow = '';
              _demo();
              _recalculate();
            });
          },
          icon: const Icon(Icons.restart_alt, color: Colors.white70),
        ),
      ],
    ),
  );
  Widget _sidebar() => Container(
    color: const Color(0xFF0D1527),
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('WORKSPACE'),
        const SizedBox(height: 9),
        _sideItem(Icons.account_tree_outlined, 'Topology canvas', true, () {}),
        _sideItem(
          Icons.alt_route_rounded,
          'Routing table',
          false,
          () => _showRoutes(),
        ),
        _sideItem(
          Icons.monitor_heart_outlined,
          'Traffic monitor',
          false,
          () => _scrollToMetrics(),
        ),
        const SizedBox(height: 23),
        const _SectionLabel('BUILD TOPOLOGY'),
        const SizedBox(height: 9),
        _sideItem(Icons.router_outlined, 'Add node', false, _addNodeDialog),
        _sideItem(
          Icons.add_link_rounded,
          'Connect link',
          false,
          _addLinkDialog,
        ),
        _sideItem(
          Icons.swap_horiz_rounded,
          'Add traffic flow',
          false,
          _addFlowDialog,
        ),
        const SizedBox(height: 23),
        const _SectionLabel('FAILURE LAB'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lineColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: orange, size: 17),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Auto disturbances',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: failureLab,
                    activeColor: orange,
                    onChanged: (v) => setState(() {
                      failureLab = v;
                      _log(
                        v
                            ? 'Automatic disturbance injection enabled.'
                            : 'Automatic disturbance injection disabled.',
                      );
                    }),
                  ),
                ],
              ),
              const Text(
                'Injects a link outage every 13 ticks while running.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cyan.withOpacity(.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cyan.withOpacity(.2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: cyan, size: 17),
              SizedBox(height: 7),
              Text(
                'Simulation mode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              SizedBox(height: 4),
              Text(
                'Models routing decisions and traffic metrics. No physical routers or packets are controlled.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'NETPILOT  •  v1.0',
          style: TextStyle(
            color: Colors.white30,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );

  Widget _sideItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: active ? Border.all(color: cyan.withOpacity(.18)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: active ? cyan : Colors.white54),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? Colors.white : Colors.white70,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _topWorkspace() => Column(
    children: [
      Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: lineColor)),
        ),
        child: Row(
          children: [
            const Text(
              'Network topology',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 10),
            _tinyPill('${nodes.length} NODES', cyan),
            const SizedBox(width: 5),
            _tinyPill(
              '${links.where((l) => l.up).length}/${links.length} LINKS UP',
              green,
            ),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: protocol,
                dropdownColor: panel,
                style: const TextStyle(fontSize: 11, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'OSPF SPF',
                    child: Text('OSPF · SPF cost'),
                  ),
                  DropdownMenuItem(
                    value: 'Capacity-aware',
                    child: Text('Capacity-aware (custom)'),
                  ),
                ],
                onChanged: (v) {
                  setState(() {
                    protocol = v ?? protocol;
                    _recalculate();
                  });
                  _log('Routing strategy changed to $protocol.');
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Add node',
              onPressed: _addNodeDialog,
              icon: const Icon(Icons.add_circle_outline, size: 19, color: cyan),
            ),
            IconButton(
              tooltip: 'Add link',
              onPressed: _addLinkDialog,
              icon: const Icon(Icons.add_link, size: 19, color: cyan),
            ),
          ],
        ),
      ),
      Expanded(
        child: Container(
          color: const Color(0xFF0A1222),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: GridPainter())),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (ctx, constraints) => GestureDetector(
                    onTapDown: (d) => _canvasTap(
                      d.localPosition,
                      Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                    onPanUpdate: (d) => _dragNode(
                      d.localPosition,
                      Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                    child: CustomPaint(
                      painter: TopologyPainter(
                        nodes: nodes,
                        links: links,
                        flows: flows,
                        selectedNode: selectedNode,
                        selectedLink: selectedLink,
                        selectedFlow: selectedFlow,
                        pendingConvergence: pendingConvergence,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(left: 15, top: 15, child: _mapLegend()),
              Positioned(
                right: 15,
                top: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _tinyPill(
                      protocol == 'OSPF SPF'
                          ? 'OSPF PROCESS'
                          : 'CUSTOM ROUTING',
                      purple,
                    ),
                    const SizedBox(height: 6),
                    _tinyPill(
                      'HELLO ${helloInterval.toStringAsFixed(0)}s  /  DEAD ${deadInterval.toStringAsFixed(0)}s',
                      Colors.white70,
                    ),
                  ],
                ),
              ),
              if (pendingConvergence)
                Positioned(
                  left: 15,
                  bottom: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: orange.withOpacity(.12),
                      border: Border.all(color: orange.withOpacity(.5)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: orange,
                          ),
                        ),
                        SizedBox(width: 9),
                        Text(
                          'SPF recalculation / route convergence…',
                          style: TextStyle(color: orange, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                right: 15,
                bottom: 15,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => setState(
                        () => canvasScale = (canvasScale - .1)
                            .clamp(.7, 1.3)
                            .toDouble(),
                      ),
                      icon: const Icon(Icons.remove, size: 16),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      onPressed: () => setState(
                        () => canvasScale = (canvasScale + .1)
                            .clamp(.7, 1.3)
                            .toDouble(),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _mapLegend() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: panel.withOpacity(.95),
      border: Border.all(color: lineColor),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIVE TOPOLOGY',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.3,
            color: Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        _LegendItem(color: cyan, text: 'Active route'),
        _LegendItem(color: lineColor, text: 'Available link'),
        _LegendItem(color: red, text: 'Failed link / node'),
        _LegendItem(color: orange, text: 'Congested link'),
      ],
    ),
  );

  void _canvasTap(Offset point, Size size) {
    NetNode? nearest;
    double distance = 9999;
    for (final n in nodes) {
      final p = Offset(n.pos.dx * size.width, n.pos.dy * size.height);
      final d = (p - point).distance;
      if (d < distance) {
        distance = d;
        nearest = n;
      }
    }
    if (tool == 'connect' && nearest != null) {
      if (connectFrom == null) {
        setState(() => connectFrom = nearest!.id);
        _snack('Now select the second endpoint.');
      } else {
        final a = connectFrom!;
        final b = nearest.id;
        setState(() => connectFrom = null);
        if (a != b) _quickLink(a, b);
      }
      return;
    }
    if (nearest != null && distance < 38) {
      setState(() {
        selectedNode = nearest!.id;
        selectedLink = '';
        selectedFlow = '';
      });
      return;
    }
    NetLink? nearLink;
    double linkDistance = 999;
    for (final l in links) {
      final a = _node(l.a), b = _node(l.b);
      if (a == null || b == null) continue;
      final d = _pointSegmentDistance(
        point,
        Offset(a.pos.dx * size.width, a.pos.dy * size.height),
        Offset(b.pos.dx * size.width, b.pos.dy * size.height),
      );
      if (d < linkDistance) {
        linkDistance = d;
        nearLink = l;
      }
    }
    if (nearLink != null && linkDistance < 14) {
      setState(() {
        selectedLink = nearLink!.id;
        selectedNode = '';
        selectedFlow = '';
      });
      return;
    }
    setState(() {
      selectedNode = '';
      selectedLink = '';
      selectedFlow = '';
    });
  }

  double _pointSegmentDistance(Offset p, Offset a, Offset b) {
    final v = b - a;
    final w = p - a;
    final denom = v.dx * v.dx + v.dy * v.dy;
    if (denom == 0) return (p - a).distance;
    final t = ((w.dx * v.dx + w.dy * v.dy) / denom).clamp(0.0, 1.0).toDouble();
    return (p - (a + v * t)).distance;
  }

  void _dragNode(Offset point, Size size) {
    if (selectedNode.isEmpty) return;
    final n = _node(selectedNode);
    if (n == null) return;
    setState(() {
      n.pos = Offset(
        (point.dx / size.width).clamp(.07, .93).toDouble(),
        (point.dy / size.height).clamp(.1, .9).toDouble(),
      );
    });
  }

  void _quickLink(String a, String b) {
    if (links.any((l) => (l.a == a && l.b == b) || (l.a == b && l.b == a))) {
      _snack('Link already exists.');
      return;
    }
    setState(() {
      final id = 'L${idSeq++}';
      links.add(NetLink(id: id, a: a, b: b));
      selectedLink = id;
      selectedNode = '';
      _recalculate();
    });
    _log('Link $a ↔ $b created with default capacity/cost.');
  }

  Widget _bottomPanel() => Container(
    decoration: const BoxDecoration(
      color: panel,
      border: Border(top: BorderSide(color: lineColor)),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Throughput',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${throughput.toStringAsFixed(1)} Mbps',
                      style: const TextStyle(
                        color: cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomPaint(
                    painter: MiniChartPainter(
                      values: throughputHistory,
                      color: cyan,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '−24 ticks',
                      style: TextStyle(fontSize: 9, color: Colors.white38),
                    ),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9,
                        color: cyan,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: lineColor),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Packet loss',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${packetLoss.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomPaint(
                    painter: MiniChartPainter(
                      values: lossHistory,
                      color: orange,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '−24 ticks',
                      style: TextStyle(fontSize: 9, color: Colors.white38),
                    ),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9,
                        color: orange,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: lineColor),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Event stream',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _tinyPill('${logs.length} EVENTS', purple),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: math.min(logs.length, 5),
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 5, color: cyan),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              logs[i],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                height: 1.35,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _inspector() => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF0D1527),
      border: Border(left: BorderSide(color: lineColor)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: lineColor)),
          ),
          child: const Row(
            children: [
              Icon(Icons.tune_rounded, size: 17, color: cyan),
              SizedBox(width: 8),
              Text(
                'Properties & controls',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedNode.isNotEmpty)
                  _nodeInspector(_node(selectedNode)!)
                else if (selectedLink.isNotEmpty)
                  _linkInspector(_link(selectedLink)!)
                else if (selectedFlow.isNotEmpty)
                  _flowInspector(flows.firstWhere((f) => f.id == selectedFlow))
                else
                  _overviewInspector(),
                const SizedBox(height: 18),
                const _SectionLabel('PROTOCOL SETTINGS'),
                const SizedBox(height: 10),
                _numberSetting(
                  'Hello interval',
                  helloInterval,
                  'seconds',
                  (v) =>
                      setState(() => helloInterval = v.clamp(1, 10).toDouble()),
                ),
                const SizedBox(height: 9),
                _numberSetting(
                  'Dead interval',
                  deadInterval,
                  'seconds',
                  (v) =>
                      setState(() => deadInterval = v.clamp(3, 30).toDouble()),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hello packets discover neighbors. If Hellos stop until the dead interval, the neighbor is declared down. This lab simplifies the timers for demonstration.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('QUICK ACTIONS'),
                const SizedBox(height: 10),
                _actionButton(
                  Icons.add_circle_outline,
                  'Add node',
                  _addNodeDialog,
                  cyan,
                ),
                const SizedBox(height: 7),
                _actionButton(Icons.add_link, 'Add link', _addLinkDialog, cyan),
                const SizedBox(height: 7),
                _actionButton(
                  Icons.waves,
                  'Add traffic flow',
                  _addFlowDialog,
                  cyan,
                ),
                const SizedBox(height: 7),
                _actionButton(
                  Icons.delete_outline,
                  'Delete selection',
                  _deleteSelected,
                  red,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _overviewInspector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Network overview',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      const Text(
        'Select a node or link on the canvas to inspect and control it.',
        style: TextStyle(color: Colors.white54, fontSize: 10, height: 1.5),
      ),
      const SizedBox(height: 14),
      _metricLine(
        'Active nodes',
        '${nodes.where((n) => n.up).length}/${nodes.length}',
        green,
      ),
      _metricLine(
        'Active links',
        '${links.where((l) => l.up).length}/${links.length}',
        cyan,
      ),
      _metricLine('Traffic flows', '${flows.length}', purple),
      _metricLine(
        'Recovery time',
        '${recoverySeconds.toStringAsFixed(1)} s',
        orange,
      ),
      const SizedBox(height: 12),
      const Text(
        'TRAFFIC FLOWS',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 9,
          letterSpacing: 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 7),
      ...flows.map(
        (f) => InkWell(
          onTap: () => setState(() {
            selectedFlow = f.id;
            selectedNode = '';
            selectedLink = '';
          }),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: f.id == selectedFlow ? cyan.withOpacity(.1) : panel,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: f.id == selectedFlow ? cyan.withOpacity(.5) : lineColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${f.delivered.toStringAsFixed(1)} Mbps',
                      style: const TextStyle(fontSize: 10, color: cyan),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${f.source} → ${f.destination} · ${f.path.length} hops',
                  style: const TextStyle(fontSize: 9, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _nodeInspector(NetNode n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(_nodeIcon(n.kind), color: n.up ? cyan : red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              n.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      _tinyPill('${n.id} · ${n.kind.toUpperCase()}', n.up ? green : red),
      const SizedBox(height: 14),
      _metricLine('Node status', n.up ? 'Online' : 'Down', n.up ? green : red),
      _metricLine(
        'Neighbors',
        '${links.where((l) => l.up && (l.a == n.id || l.b == n.id)).length}',
        cyan,
      ),
      _metricLine(
        'Last Hello',
        n.kind == 'router'
            ? (n.up ? '${tick - n.lastHello}s ago' : 'Timed out')
            : 'N/A',
        purple,
      ),
      const SizedBox(height: 12),
      _actionButton(
        n.up ? Icons.power_settings_new : Icons.restart_alt,
        n.up ? 'Fail this node' : 'Restore node',
        () {
          if (n.up) {
            _failNode(n.id);
          } else {
            _restoreNode(n.id);
          }
        },
        n.up ? red : green,
      ),
    ],
  );

  Widget _linkInspector(NetLink l) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Link properties',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      _tinyPill('${l.id} · ${l.a} ↔ ${l.b}', l.up ? green : red),
      const SizedBox(height: 13),
      _metricLine(
        'Status',
        l.up ? 'Operational' : 'FAILED',
        l.up ? green : red,
      ),
      _metricLine(
        'Utilization',
        '${(l.used / math.max(1, l.capacity) * 100).clamp(0, 100).toStringAsFixed(0)}%',
        l.used / math.max(1, l.capacity) > .8 ? orange : cyan,
      ),
      _metricLine(
        'Used / capacity',
        '${l.used.toStringAsFixed(1)} / ${l.capacity.toStringAsFixed(0)} Mbps',
        cyan,
      ),
      const SizedBox(height: 13),
      _editableNumber('Capacity (Mbps)', l.capacity, (v) {
        setState(() {
          l.capacity = v.clamp(1, 10000).toDouble();
          _recalculate();
        });
      }),
      const SizedBox(height: 8),
      _editableNumber('OSPF cost', l.cost, (v) {
        setState(() {
          l.cost = v.clamp(1, 65535).toDouble();
          _recalculate();
        });
      }),
      const SizedBox(height: 8),
      _editableNumber('Delay (ms)', l.delay, (v) {
        setState(() {
          l.delay = v.clamp(0, 5000).toDouble();
          _recalculate();
        });
      }),
      const SizedBox(height: 8),
      _editableNumber('Loss (%)', l.loss, (v) {
        setState(() {
          l.loss = v.clamp(0, 100).toDouble();
          _recalculate();
        });
      }),
      const SizedBox(height: 13),
      _actionButton(
        l.up ? Icons.link_off : Icons.link,
        l.up ? 'Simulate link failure' : 'Restore link',
        () {
          if (l.up)
            _failLink(l.id);
          else
            _restoreLink(l.id);
        },
        l.up ? red : green,
      ),
    ],
  );

  Widget _flowInspector(NetFlow f) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Traffic flow',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      _tinyPill(f.id, purple),
      const SizedBox(height: 12),
      Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 7),
      _metricLine(
        'Source → destination',
        '${f.source} → ${f.destination}',
        cyan,
      ),
      _metricLine('Delivered', '${f.delivered.toStringAsFixed(1)} Mbps', green),
      _metricLine('Latency', '${f.latency.toStringAsFixed(1)} ms', purple),
      _metricLine(
        'Packet loss',
        '${f.loss.toStringAsFixed(2)}%',
        f.loss > 0 ? orange : green,
      ),
      const SizedBox(height: 12),
      _editableNumber(
        'Demand (Mbps)',
        f.demand,
        (v) => setState(() {
          f.demand = v.clamp(0, 10000).toDouble();
          _recalculate();
        }),
      ),
      const SizedBox(height: 10),
      const Text(
        'Current route',
        style: TextStyle(fontSize: 10, color: Colors.white54),
      ),
      const SizedBox(height: 5),
      Text(
        f.path.isEmpty ? 'No available route' : f.path.join('  →  '),
        style: const TextStyle(fontSize: 10, color: cyan, height: 1.5),
      ),
    ],
  );

  Widget _numberSetting(
    String title,
    double value,
    String suffix,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} $suffix',
            style: const TextStyle(fontSize: 10, color: cyan),
          ),
        ],
      ),
      Slider(
        value: value,
        min: title.startsWith('Hello') ? 1 : 3,
        max: title.startsWith('Hello') ? 10 : 30,
        divisions: title.startsWith('Hello') ? 9 : 27,
        activeColor: cyan,
        onChanged: onChanged,
      ),
    ],
  );
  Widget _editableNumber(
    String title,
    double value,
    ValueChanged<double> onChanged,
  ) {
    final c = TextEditingController(
      text: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
    );
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: title,
        suffixIcon: IconButton(
          icon: const Icon(Icons.check, color: cyan, size: 18),
          onPressed: () {
            final v = double.tryParse(c.text);
            if (v != null)
              onChanged(v);
            else
              _snack('Enter a valid number.');
          },
        ),
      ),
      onSubmitted: (s) {
        final v = double.tryParse(s);
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 10)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        alignment: Alignment.centerLeft,
        side: BorderSide(color: color.withOpacity(.35)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      ),
    ),
  );
  Widget _metricLine(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _tinyPill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(.10),
      border: Border.all(color: color.withOpacity(.25)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 8,
        letterSpacing: .5,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
  Widget _statusDot(Color color) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color.withOpacity(.5), blurRadius: 7)],
    ),
  );
  Widget _mobileBody() => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        const TabBar(
          tabs: [
            Tab(text: 'Topology'),
            Tab(text: 'Metrics'),
            Tab(text: 'Controls'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              Column(
                children: [
                  Expanded(child: _topWorkspace()),
                  SizedBox(height: 180, child: _bottomPanel()),
                ],
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(height: 220, child: _bottomPanel()),
                    const SizedBox(height: 16),
                    _overviewInspector(),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _overviewInspector(),
                    const SizedBox(height: 18),
                    _actionButton(Icons.add, 'Add node', _addNodeDialog, cyan),
                    _actionButton(
                      Icons.add_link,
                      'Add link',
                      _addLinkDialog,
                      cyan,
                    ),
                    _actionButton(
                      Icons.waves,
                      'Add flow',
                      _addFlowDialog,
                      cyan,
                    ),
                    _actionButton(
                      Icons.delete,
                      'Delete selection',
                      _deleteSelected,
                      red,
                    ),
                    SwitchListTile(
                      title: const Text('Automatic disturbances'),
                      value: failureLab,
                      onChanged: (v) => setState(() => failureLab = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _showRoutes() => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: panel,
      title: const Text('Current routing table'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Flow')),
              DataColumn(label: Text('Destination')),
              DataColumn(label: Text('Route')),
            ],
            rows: flows
                .map(
                  (f) => DataRow(
                    cells: [
                      DataCell(Text(f.id)),
                      DataCell(Text(f.destination)),
                      DataCell(
                        Text(
                          f.path.isEmpty ? 'Unreachable' : f.path.join(' → '),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
  void _scrollToMetrics() =>
      _snack('Live charts are shown in the bottom metrics panel.');
}

IconData _nodeIcon(String kind) => kind == 'router'
    ? Icons.router_rounded
    : kind == 'server'
    ? Icons.dns_rounded
    : Icons.computer_rounded;

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 9,
      color: Colors.white38,
      letterSpacing: 1.3,
      fontWeight: FontWeight.bold,
    ),
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(fontSize: 9, color: Colors.white70)),
      ],
    ),
  );
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1C2A41)
      ..strokeWidth = .5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TopologyPainter extends CustomPainter {
  TopologyPainter({
    required this.nodes,
    required this.links,
    required this.flows,
    required this.selectedNode,
    required this.selectedLink,
    required this.selectedFlow,
    required this.pendingConvergence,
  });
  final List<NetNode> nodes;
  final List<NetLink> links;
  final List<NetFlow> flows;
  final String selectedNode, selectedLink, selectedFlow;
  final bool pendingConvergence;
  @override
  void paint(Canvas canvas, Size size) {
    Offset point(NetNode n) =>
        Offset(n.pos.dx * size.width, n.pos.dy * size.height);
    final routeIds = <String>{};
    for (final f in flows) {
      if (selectedFlow.isEmpty || f.id == selectedFlow) routeIds.addAll(f.path);
    }
    for (final l in links) {
      NetNode? a;
      NetNode? b;
      for (final n in nodes) {
        if (n.id == l.a) a = n;
        if (n.id == l.b) b = n;
      }
      if (a == null || b == null) continue;
      final p1 = point(a), p2 = point(b);
      final isRoute = routeIds.contains(l.id);
      final congested = l.capacity > 0 && l.used / l.capacity > .8;
      final color = !l.up || !a.up || !b.up
          ? red
          : isRoute
          ? cyan
          : congested
          ? orange
          : const Color(0xFF3B4A65);
      final paint = Paint()
        ..color = color.withOpacity(isRoute ? .95 : .7)
        ..strokeWidth = l.id == selectedLink
            ? 3.5
            : isRoute
            ? 2.8
            : 1.5;
      if (!l.up || !a.up || !b.up) {
        _drawDashed(canvas, p1, p2, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final label =
          '${l.id}  ${l.used.toStringAsFixed(0)}/${l.capacity.toStringAsFixed(0)}';
      _text(
        canvas,
        label,
        mid + const Offset(0, -10),
        TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
        alignCenter: true,
      );
      if (isRoute && l.up) {
        final v = p2 - p1;
        final norm = math.sqrt(v.dx * v.dx + v.dy * v.dy);
        if (norm > 0) {
          final q = mid + Offset(v.dx / norm * 9, v.dy / norm * 9);
          canvas.drawCircle(q, 3.2, Paint()..color = cyan);
        }
      }
    }
    for (final n in nodes) {
      final p = point(n);
      final selected = n.id == selectedNode;
      final color = n.up
          ? (n.kind == 'router'
                ? cyan
                : n.kind == 'server'
                ? purple
                : green)
          : red;
      if (selected)
        canvas.drawCircle(p, 30, Paint()..color = color.withOpacity(.12));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: 44, height: 42),
          const Radius.circular(12),
        ),
        Paint()
          ..color = n.up ? const Color(0xFF15243A) : const Color(0xFF3A1A2B),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: 44, height: 42),
          const Radius.circular(12),
        ),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2 : 1,
      );
      _drawNodeGlyph(canvas, p, n.kind, color);
      _text(
        canvas,
        n.id,
        p + const Offset(0, 31),
        TextStyle(
          color: n.up ? Colors.white : red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        alignCenter: true,
      );
      _text(
        canvas,
        n.name,
        p + const Offset(0, 44),
        const TextStyle(color: Colors.white60, fontSize: 9),
        alignCenter: true,
      );
      if (!n.up) {
        canvas.drawCircle(p + const Offset(17, -16), 5, Paint()..color = red);
        _text(
          canvas,
          '×',
          p + const Offset(17, -16),
          const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
          alignCenter: true,
        );
      }
    }
  }

  void _drawNodeGlyph(Canvas canvas, Offset p, String kind, Color c) {
    final paint = Paint()
      ..color = c
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    if (kind == 'router') {
      canvas.drawCircle(p, 8, paint);
      canvas.drawLine(p + const Offset(-12, 0), p + const Offset(12, 0), paint);
      canvas.drawLine(p + const Offset(0, -12), p + const Offset(0, 12), paint);
    } else if (kind == 'server') {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: p, width: 17, height: 19),
        const Radius.circular(2),
      );
      canvas.drawRRect(r, paint);
      canvas.drawLine(p + const Offset(-5, -3), p + const Offset(5, -3), paint);
      canvas.drawLine(p + const Offset(-5, 2), p + const Offset(5, 2), paint);
      canvas.drawCircle(p + const Offset(5, 6), 1, Paint()..color = c);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: p + const Offset(0, -2),
            width: 19,
            height: 13,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.drawLine(p + const Offset(0, 5), p + const Offset(0, 9), paint);
      canvas.drawLine(p + const Offset(-6, 9), p + const Offset(6, 9), paint);
    }
  }

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final d = b - a;
    final length = d.distance;
    if (length == 0) return;
    final unit = d / length;
    for (double i = 0; i < length; i += 10) {
      canvas.drawLine(a + unit * i, a + unit * math.min(i + 5, length), paint);
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style, {
    bool alignCenter = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        center.dx - (alignCenter ? tp.width / 2 : 0),
        center.dy - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant TopologyPainter old) => true;
}

class MiniChartPainter extends CustomPainter {
  MiniChartPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    final grid = Paint()
      ..color = lineColor.withOpacity(.6)
      ..strokeWidth = .6;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final minV = values.reduce(math.min), maxV = values.reduce(math.max);
    final range = math.max(1.0, maxV - minV);
    final pts = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      pts.add(
        Offset(
          size.width * i / math.max(1, values.length - 1),
          size.height - 5 - ((values[i] - minV) / range) * (size.height - 12),
        ),
      );
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(.22), color.withOpacity(.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(pts.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant MiniChartPainter old) => true;
}
