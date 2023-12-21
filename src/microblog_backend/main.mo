import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

actor {
  public type Message = {
    text : Text;
    time : Time.Time;
  };

  public type Microblog = actor {
    follow : shared (Principal) -> async ();
    follows : shared query () -> async [Principal];
    post : shared (Text) -> async ();
    posts : shared query (Time.Time) -> async [Message];
    timeline : shared (Time.Time) -> async [Message];
  };

  stable var followed : List.List<Principal> = List.nil(); //empty list

  public shared func follow(id : Principal) : async () {
    followed := List.push(id, followed);
  };

  public shared query func follows() : async [Principal] {
    List.toArray(followed);
  };

  stable var messages : List.List<Message> = List.nil();

  public shared func post(text : Text) : async () {
    let newMessage : Message = {
      text = text;
      time = Time.now();
    };
    messages := List.push(newMessage, messages);
  };

  public shared query func posts(since : Time.Time) : async [Message] {
    var posts_since : List.List<Message> = List.nil();

    for (msg in Iter.fromList(messages)) {
      if (msg.time > since) {
        posts_since := List.push(msg, posts_since);
      };
    };

    List.toArray(posts_since);
  };

  public shared func timeline(since : Time.Time) : async [Message] {
    var all : List.List<Message> = List.nil();

    for (id in Iter.fromList(followed)) {
      let canister : Microblog = actor (Principal.toText(id));
      let msgs = await canister.posts(since);
      
      // merge by time in descending order
      all := List.merge(
        all,
        List.fromArray(msgs),
        func(m1 : Message, m2 : Message) : Bool {
          m1.time >= m2.time;
        },
      );
    };

    List.toArray(all);
  };
};
