import 'dart:convert';
import 'package:mimu/data/services/signal_service.dart';
import 'package:mimu/data/user_api.dart';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/features/calls/signal_double_ratchet.dart';
import 'package:mimu/features/calls/sender_key_crypto.dart';
import 'package:mimu/features/calls/signal_crypto_real.dart';

class DistributionMessage {
  final String recipientId;
  final String payload; // Encrypted for recipient
  DistributionMessage(this.recipientId, this.payload);
}

/// E2EE for messages using Signal Protocol (Double Ratchet).
/// Replaces the legacy symmetric key implementation.
class MessageE2EE {
  /// Encrypt JSON payload for 1-to-1 chat using Signal Protocol (Double Ratchet).
  /// [recipientUserId] must be the User ID of the recipient (not Chat ID).
  static Future<String> encryptJsonForOneToOne(String recipientUserId, Map<String, dynamic> payload) async {
    final peerId = recipientUserId;
    
    final plaintext = jsonEncode(payload);
    
    // SignalService.crypto is the singleton instance
    final signal = SignalService().crypto;
    
    try {
      // Try to encrypt immediately (assuming session exists)
      if (signal is RealSignalCrypto) {
         return await signal.encryptForPeer(plaintext, peerId);
      } else {
         return signal.encryptToBase64(plaintext); // Fallback or throw
      }
    } catch (e) {
      // If session missing, fetch PreKeys and initialize X3DH
      if (e.toString().contains('No session') && signal is DoubleRatchetSignalCrypto) {
        try {
          print('E2EE: No session for $peerId, fetching PreKeys...');
          
          // 1. Fetch PreKey Bundle from server
          final preKeyBundle = await UserApi().getPreKeys(peerId);
          if (preKeyBundle.isEmpty) {
             throw Exception('Failed to fetch PreKeys for user $peerId');
          }
          
          // 2. Initialize Session (X3DH)
          await signal.initializeSession(peerId, preKeyBundle);
          print('E2EE: Session initialized for $peerId');
          
          // 3. Retry encryption
          return signal.encryptToBase64(plaintext);
        } catch (initError) {
          print('E2EE: Initialization failed: $initError');
          throw Exception('Failed to establish secure session with $peerId: $initError');
        }
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> decryptJson({
    required String chatId, 
    required String senderId, 
    required String encryptedPayloadBase64,
    required bool isGroup,
  }) async {
    if (isGroup) {
       return decryptJsonForGroup(chatId, senderId, encryptedPayloadBase64);
    } else {
       final signal = SignalService().crypto;
       try {
         // For 1-to-1, senderId is the peer ID
         if (signal is RealSignalCrypto) {
            final plaintext = await signal.decryptForPeer(encryptedPayloadBase64, senderId);
            return jsonDecode(plaintext) as Map<String, dynamic>;
         } else {
            final plaintext = signal.decryptFromBase64(encryptedPayloadBase64);
            return jsonDecode(plaintext) as Map<String, dynamic>;
         }
       } catch (e) {
         print('Decryption failed for $chatId from $senderId: $e');
         rethrow;
       }
    }
  }

  static Future<List<DistributionMessage>> distributeKeyToParticipants(String groupId, List<String> participantIds) async {
    final myUserId = UserService.getUserId();
    if (myUserId == null) throw Exception('User not logged in');
    
    final senderKeyCrypto = SignalService().senderKeyCrypto;
    
    SenderKeyDistributionMessage distMsg;
    
    if (senderKeyCrypto.hasSession(groupId, myUserId)) {
      distMsg = senderKeyCrypto.getDistributionMessage(groupId, myUserId);
    } else {
      distMsg = await senderKeyCrypto.createSession(groupId, myUserId);
    }
    
    final result = <DistributionMessage>[];
    
    for (final pid in participantIds) {
      if (pid == myUserId) continue;
      
      final payload = {
        't': 'sender_key_dist',
        'content': distMsg.toJson(),
      };
      
      try {
        final encrypted = await encryptJsonForOneToOne(pid, payload);
        result.add(DistributionMessage(pid, encrypted));
      } catch (e) {
        print('Failed to encrypt distribution message for $pid: $e');
      }
    }
    
    return result;
  }

  /// Ensure we have a Sender Key session for this group.
  /// Returns a list of distribution messages that MUST be sent to participants before sending the group message.
  static Future<List<DistributionMessage>> ensureGroupSession(String groupId, List<String> participantIds) async {
    final myUserId = UserService.getUserId();
    if (myUserId == null) throw Exception('User not logged in');
    
    final senderKeyCrypto = SignalService().senderKeyCrypto;
    
    if (senderKeyCrypto.hasSession(groupId, myUserId)) {
      return [];
    }
    
    // Create session
    final distMsg = await senderKeyCrypto.createSession(groupId, myUserId);
    
    final result = <DistributionMessage>[];
    
    for (final pid in participantIds) {
      if (pid == myUserId) continue;
      
      // Encrypt distMsg for pid using 1-to-1 session
      final payload = {
        't': 'sender_key_dist',
        'content': distMsg.toJson(),
      };
      
      try {
        final encrypted = await encryptJsonForOneToOne(pid, payload);
        result.add(DistributionMessage(pid, encrypted));
      } catch (e) {
        print('Failed to encrypt distribution message for $pid: $e');
        // Continue for other participants? Or fail?
        // If we fail to distribute to one, that user won't be able to decrypt.
        // We should probably continue but log it.
      }
    }
    
    return result;
  }
  
  static Future<String> encryptJsonForGroup(String groupId, Map<String, dynamic> payload) async {
    final myUserId = UserService.getUserId();
    if (myUserId == null) throw Exception('User not logged in');
    
    final senderKeyCrypto = SignalService().senderKeyCrypto;
    final plaintext = jsonEncode(payload);
    
    return await senderKeyCrypto.encryptForGroup(groupId, myUserId, plaintext);
  }
  
  static Future<Map<String, dynamic>> decryptJsonForGroup(String groupId, String senderId, String encryptedBase64) async {
     final senderKeyCrypto = SignalService().senderKeyCrypto;
     final plaintext = await senderKeyCrypto.decryptForGroup(groupId, senderId, encryptedBase64);
     return jsonDecode(plaintext) as Map<String, dynamic>;
  }
}

