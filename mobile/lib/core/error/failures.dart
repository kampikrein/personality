sealed class Failure {
  const Failure(this.message);
  final String message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database error occurred']);
}

class SensorFailure extends Failure {
  const SensorFailure([super.message = 'Sensor not available']);
}

class ShuffleFailure extends Failure {
  const ShuffleFailure([super.message = 'Shuffle failed']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}
