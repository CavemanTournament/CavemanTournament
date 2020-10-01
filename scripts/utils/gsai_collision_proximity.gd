extends GSAIProximity
class_name GSAICollisionProximity

var params: PhysicsShapeQueryParameters
var owner: Node
var shape: Shape

func _init(agent: GSAISteeringAgent, _owner: Node, _shape: Shape = null).(agent, []) -> void:
	self.params = PhysicsShapeQueryParameters.new()
	self.params.exclude = [_owner]
	
	self.owner = _owner
	self.shape = _shape

# Detects any collision at the agent's vicinity and reports the collision point as a neighbor
func _find_neighbors(callback: FuncRef) -> int:
	if !self.owner || !self.shape:
		return 0

	self.params.set_shape(self.shape)
	self.params.transform = Transform(Basis(), self.agent.position)
	
	var rest_info = self.owner.get_world().direct_space_state.get_rest_info(self.params)
	
	if rest_info.has('collider_id'):
		var collision_agent = GSAISteeringAgent.new()
		collision_agent.position = rest_info.point
		
		if callback.call_func(collision_agent):
			return 1

	return 0
