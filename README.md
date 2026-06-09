# take-home-assignment

## Explanation of Approach

In this assignment, I determined a main priority to be scalability and performance, and therefore chose to center the design of my implementation around achieving this.

  

To begin the system, I chose to utilize the CollectionService API to query assets from the datamodel as it would aid in designing resiliency to the effects of instance streaming, which is a common pitfall for systems like this one. It would also allow my system to react dynamically to changes in the DataModel and give freedom to other team members about where to place assets, as opposed to searching for a predefined location.

  

The architecture of the conveyor system itself is object oriented and has mirrored classes on both the client and server side. This approach enables incredibly fast prototyping and scalability as there are no restrictions for how each class can utilize eachother and how they can be extended. It also enables writing highly intuitive and straight-forward logic that is less intimidating for onboarding team members or reviewers.

  

As for the underlying design choice of how to handle replicating baggages between the server and client, I decided to implement a client-first approach which delegates the full responsibility of animating and visualizing baggage objects on the client. There are a few reasons I chose this approach:

* Placing the responsibility of performing and rendering visual effects on the server can cause stuttering and visual inconsistencies while also using much more network bandwidth than is required.

* Giving the client control of the visualization process allows for much more freedom in how objects are rendered and decouples the client from a server-controlled object.

* Having the server control these objects, especially as there may be hundreds of them, greatly reduces server performance and would often lead to a far worse player experience.

  

As for the technical implementation, I chose to represent bags as Folder instances where properties are replicated to the client using attributes. I chose this approach over using RemoteEvents as it allows us to utilize methods and instance management techniques that are already native to the engine. This is the primary driver for this system's networking so that both client and server are simply responsible for responding to and managing simple instances in the data model, no complex remote exchanges necessary. The mechanism used for keeping the client and server in-sync in the workspace:GetServerTimeNow() method, which is designed to give microsecond-level precision for this exact synchronization purpose. I also implemented the click functionality using a basic ClickDetector that is created on the client. When the client clicks a bag, it informs the server which then performs validation and a distance check to prevent invalid requests before responding to the request (in this case, printing the bag id).

  

The user interface is quite simple and implements a basic UIDragDetector for the slider. At startup, the server assigns a particular player the GUI and will only accept their requests to change the interval. The user interface also implements a basic rate limiting system which reduces network bandwidth usage while keeping the interface highly responsive.

  

Overall, I chose this approach due to its high extensibility, performance, and potential for rapid iteration.

  
  

## Open-ended Question

  

In designing a system for skill-based matchmaking, it is first important to decide the parameters you will use to match players. I would begin by having some system in place for collecting statistics about a player's gameplay, indicators like time played and in-game level would likely be most pertinent for matchmaking, while indicators such as win rate and kdr could weigh it slightly. These statistics would likely be stored within the player's DataStore profile and updated frequently. Taking these indicators, I would write a function that maps them to an elo or skill rating which can be used for matchmaking. Providing players access to their calculated elo (like ranks in competitive games) would be an option, but is more a feature than a requirement.

  

Once players would like to queue up for competitive matchmaking, we can first assess the size of their party. A decent approximation for a "Party Elo" would be a simple average of each party member. As for how to actually matchmake, a good candidate API for this would be the MemoryStoreService. Specifically, I would use MemoryStore's SortedMap to implement a nearest-elo matchmaking system for minimizing the elo disparity between parties. For each party size (1v1, 2v2, 3v3), a seperate SortedMap can be defined. When players queue up, their elo is used to sort them among the other players that are queued. Given the elo disparity between their nearest neighbors, a linear function can be applied for how much time players must wait for leniency (i.e., the allowed discrepancy increases over time to prevent players waiting indefinitely). Once a server identifies that another party exists within a desired elo range, MessagingService can be used by the two servers players are queuing from (using their jobIds for identification) to either deny the match (if the other party is inadequate, for some reason), or agree and reserve a server for the players to be sent to. At this step, the matchmaking is complete and the players are removed from queue. Additional care would need to be taken about players dequeuing right before being matched, perhaps with a time buffer or through the MessagingService handshake.

  

If you wanted to implement a solo-queue for 2v2 or 3v3 parties (where a single player queues with other teammates randomly), you could likely accomplish this by maintaining a separate SortedMap for individuals looking to queue with random players and match them in a similar process as outline above. Then you could treat them as a party and queue them for a larger party match.