module netsim.project;

import netsim.network.node;
import netsim.network.nodes.docker;
import netsim.network.nodes.qemu;
import netsim.query;

import std.exception : enforce;
import std.format : format;
import std.uuid : UUID;

final class Project : Queryable
{
  private UUID id;
  private string name;

  private Node[UUID] nodes;

  ///
  // Constructors / Destructor
  ///

  this(UUID id, string name)
  {
    this.id = id;
    this.name = name;
  }

  ~this()
  {
    foreach (node; nodes)
      destroy(node);
  }

  ///
  // Adding nodes
  ///

  void addDockerNode(UUID id, string name)
  {
    nodes[id] = cast(Node) new DockerNode(id, name);
    nodes.rehash;
  }

  void addQemuNode(UUID id, string name, string image, string mac)
  {
    nodes[id] = cast(Node) new QemuNode(id, name, image, mac);
    nodes.rehash;
  }

  /// 
  // Removing nodes
  ///

  void removeNode(UUID id)
  {
    enforce(nodeExists(id), format!"removeNode failed: node with id %s does not exist in this project"(
        id));
    bool result = nodes.remove(id);
    assert(result);
  }

  ///
  // Accessing nodes
  ///

  bool nodeExists(UUID id)
  {
    return (id in nodes) !is null;
  }

  Node getNode(UUID id)
  {
    Node* node = id in nodes;
    enforce(node !is null, format!"getNode failed: node with id %s does not exist in this project"(
        id));
    return *node;
  }

  UUID[] listNodeIds()
  {
    return nodes.keys;
  }

  ///
  // Implementing Queryable
  ///

  mixin resolveMixin!getNode;
  // mixin queryMixin!(nodeExists, getNode, listNodeIds);
  // mixin subscribeMixin!(...);
  // mixin unsubscribeMixin!(...);

  string query(QuerySegment segment)
  in (segment.type == QuerySegmentType.Method)
  {
    return "";
  }

  void subscribe(QuerySegment segment, void delegate(string) hook)
  in (segment.type == QuerySegmentType.Signal)
  {
  }

  void unsubscribe(QuerySegment segment, void delegate(string) hook)
  in (segment.type == QuerySegmentType.Signal)
  {
  }

  ///
  // wip
  ///

  mixin Signal!(string) s1;
  mixin Signal!(string) s2;

  void addNodeQuery(NodeType type)()
  {
    static if (type == NodeType.Docker)
    {
    }
    else static if (type == NodeType.Qemu)
    {

    }
    else
      static assert(false, format!"Invalid node type (%s)"(type));
  }
}
