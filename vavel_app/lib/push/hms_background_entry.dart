import 'package:huawei_push/huawei_push.dart' show RemoteMessage;

import '../utils/logger.dart';

@pragma('vm:entry-point')
void huaweiMessagingBackgroundMessageHandler(RemoteMessage message) {
  logger.i(
    'Background Huawei Push: data=${message.data} msgId=${message.messageId}',
  );
}
