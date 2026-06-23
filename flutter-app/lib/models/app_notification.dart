class AppNotification {

  final String id;

  final String title;

  final String body;

  final String when;

  final String type;

  final bool isRead;

  final String? peerUserId;



  const AppNotification({

    required this.id,

    required this.title,

    required this.body,

    required this.when,

    this.type = 'system',

    this.isRead = false,

    this.peerUserId,

  });



  bool get isMessage => type == 'message';



  Map<String, String> toFeedItem() => {

        'category': type,

        'title': title,

        'body': body,

        'when': when,

      };

}

