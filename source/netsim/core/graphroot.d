module netsim.core.graphroot;

import netsim.core.project : Project;
import netsim.core.thread : stopGraphThread;
import netsim.graph.apiserver : MessageToSend, ParsedMessage, parsedQueue, toSendQueue;
import netsim.graph.graph : GraphNode, handleRequest, queryMixin, resolveMixin;

import std.concurrency : receiveTimeout, send, spawn, Tid;
import std.datetime.stopwatch : AutoStart, StopWatch;
import std.exception : collectException, enforce;
import std.format : format;
import std.stdio : writefln, writeln;
import std.uuid : UUID;

import core.thread : Thread;
import core.time : Duration, msecs;

///                  ///
// Thread entry point //
///                  ///

void graphThreadEntryPoint() @trusted nothrow
{
  try
  {
    GraphRoot graphRoot = new GraphRoot;

    import std.uuid : randomUUID;

    UUID uuid = randomUUID;
    graphRoot.projects[uuid] = new Project(uuid, "test project");

    while (!stopGraphThread)
    {
      graphRoot.processGraphApiRequests(10.msecs);
    }
  }
  catch (Exception e)
  {
    collectException({
      // TODO: log instead
      writeln(e);
    });
  }
}

///               ///
// GraphRoot class //
///               ///

final class GraphRoot : GraphNode
{
  private Project[UUID] projects;

  ///
  // Constructors / Destructor
  ///

  this()
  {
  }

  ~this()
  {
    // TODO
  }

  ///
  // Accessing projects
  ///

  Project[] getProjects()
  {
    return projects.values;
  }

  bool projectExists(UUID id)
  {
    return (id in projects) !is null;
  }

  Project getProject(UUID id)
  {
    Project* project = id in projects;
    enforce(projects !is null, format!"getProject failed: project with id %s does not exist"(id));
    return *project;
  }

  UUID[] listProjectIds()
  {
    return projects.keys;
  }

  ///
  // Implementing GraphNode
  ///

  mixin resolveMixin!(getProject);
  mixin queryMixin!(getProjects, projectExists, getProject, listProjectIds);

  ///
  // For GraphApiServer
  ///

  void processGraphApiRequests(in Duration returnAfter)
  {
    alias sleep = () => Thread.sleep(1.msecs);
    StopWatch sw = StopWatch(AutoStart.yes);

    while (sw.peek < returnAfter)
    {
      // writeln("graph loop");
      // parsedQueue.empty;
      if (parsedQueue.empty)
        sleep();
      else
      {
        auto front = parsedQueue.pop;
        if (front.isNull)
        {
          // something popped the front between our parsedQueue.empty call and our parsedQueue.pop call
          // Todo: log this
          sleep();
        }
        else
        {
          immutable ParsedMessage parsedMessage = front.get;
          string responseStr = handleRequest(parsedMessage.request, this); // handleRequest is nothrow
          toSendQueue.push(MessageToSend(
              parsedMessage.requestId, responseStr
          ));
        }
      }
    }
  }
}
