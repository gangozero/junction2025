/// Control remote data source
library;

import 'package:graphql_flutter/graphql_flutter.dart';

import '../../domain/entities/command_request.dart';
import '../models/command_response_dto.dart';
import '../models/power_command_dto.dart';
import '../../../../services/api/graphql/graphql_client.dart';

/// Control remote data source
///
/// Handles GraphQL mutations for device control commands
class ControlRemoteDataSource {
  final GraphQLClient client;

  const ControlRemoteDataSource({required this.client});

  /// Default constructor using GraphQLClientService
  factory ControlRemoteDataSource.create() {
    return ControlRemoteDataSource(
      client: GraphQLClientService.getClient() as GraphQLClient,
    );
  }

  /// Send device command mutation
  Future<CommandResponseDto> sendDeviceCommand({
    required CommandRequest command,
  }) async {
    try {
      final mutation = _buildMutation(command);
      final variables = _buildVariables(command);

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw _handleException(result.exception!);
      }

      final data = result.data?['sendDeviceCommand'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('No data returned from mutation');
      }

      return CommandResponseDto.fromJson(data);
    } catch (e) {
      if (e is OperationException) rethrow;
      throw Exception('Failed to send command: $e');
    }
  }

  /// Build GraphQL mutation based on command type
  String _buildMutation(CommandRequest command) {
    return switch (command.type) {
      CommandType.powerOn || CommandType.powerOff =>
        '''
        mutation SendPowerCommand(\$deviceId: ID!, \$powerOn: Boolean!) {
          sendDeviceCommand(input: {
            deviceId: \$deviceId
            commandType: POWER
            parameters: { powerOn: \$powerOn }
          }) {
            success
            message
            errorCode
            data
          }
        }
      ''',
      CommandType.setTemperature =>
        '''
        mutation SendTemperatureCommand(\$deviceId: ID!, \$targetTemperature: Float!) {
          sendDeviceCommand(input: {
            deviceId: \$deviceId
            commandType: SET_TEMPERATURE
            parameters: { targetTemperature: \$targetTemperature }
          }) {
            success
            message
            errorCode
            data
          }
        }
      ''',
      CommandType.unknown => throw Exception(
        'Cannot send unknown command type',
      ),
    };
  }

  /// Build variables for GraphQL mutation
  Map<String, dynamic> _buildVariables(CommandRequest command) {
    return switch (command.type) {
      CommandType.powerOn ||
      CommandType.powerOff => PowerCommandDto.fromEntity(command).toGraphQL(),
      CommandType.setTemperature => {
        'deviceId': command.deviceId,
        'targetTemperature': command.parameters['targetTemperature'],
      },
      CommandType.unknown => throw Exception(
        'Cannot build variables for unknown command type',
      ),
    };
  }

  /// Handle GraphQL exception
  OperationException _handleException(OperationException exception) {
    // Just return the exception as-is, repository layer will handle conversion
    return exception;
  }
}
