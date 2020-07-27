class_name Graph

var edges = {}
var edge_weights = {}
var nodes = []

func add_node(_node):
	nodes.append(_node)
	edges[_node] = []
	edge_weights[_node] = []

func add_edge(_node1, _node2, _weight = 0):
	edges[_node1].append(_node2)
	edges[_node2].append(_node1)
	edge_weights[_node1].append(_weight)
	edge_weights[_node2].append(_weight)

func mst():
	var graph = get_script().new()

	if (nodes.size() == 0):
		return graph

	var start = nodes[0]
	var edge_queue = PriorityQueue.new()
	var visited = {}
	visited[start] = true
	graph.add_node(start)

	for i in range(edges[start].size()):
		edge_queue.push([start, edges[start][i]], edge_weights[start][i])

	var current_edge = edge_queue.pop()
	while edge_queue.size() > 0:
		while edge_queue.size() > 0 && (current_edge[1] in visited):
			current_edge = edge_queue.pop()

		var node = current_edge[1]

		if !(node in visited):
			graph.add_node(node)
			graph.add_edge(current_edge[0], node)

			for i in range(edges[node].size()):
				edge_queue.push([node, edges[node][i]], edge_weights[node][i])

			visited[node] = true

	return graph
