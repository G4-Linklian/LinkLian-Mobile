import 'package:LinkLian/core/error/failure.dart';
import 'package:dartz/dartz.dart';

abstract class UseCase<Response, Params> {
  Future<Either<Failure, Response>> call(Params params);
}

class NoParams {}
