class_name Graph

var edges = {}
var edge_weights = {}
var nodes = []

func add_node(node):
	self.nodes.append(node)
	self.edges[node] = []
	self.edge_weights[node] = []

func add_edge(node1, node2, weight = 0):
	self.edges[node1].append(node2)
	self.edges[node2].append(node1)
	self.edge_weights[node1].append(weight)
	self.edge_weights[node2].append(weight)

func mst():
	var graph = get_script().new()

	if (self.nodes.size() == 0):
		return graph

	var start = self.nodes[0]
	var edge_queue = PriorityQueue.new()
	var visited = {}
	visited[start] = true
	graph.add_node(start)

	for i in range(self.edges[start].size()):
		edge_queue.push([start, self.edges[start][i]], self.edge_weights[start][i])

	var current_edge = edge_queue.pop()
	while edge_queue.size() > 0:
		while edge_queue.size() > 0 && (current_edge[1] in visited):
			current_edge = edge_queue.pop()

		var node = current_edge[1]

		if !(node in visited):
			graph.add_node(node)
			graph.add_edge(current_edge[0], node)

			for i in range(edges[node].size()):
				edge_queue.push([node, self.edges[node][i]], self.edge_weights[node][i])

			visited[node] = true

	return graph
