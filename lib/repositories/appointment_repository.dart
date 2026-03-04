import 'package:agendo/models/appointment_model.dart';

class AppointmentRepository {
  // Simulando a API e o Banco Local
  Future<List<AppointmentModel>> fetchAppointments() async {
    // fluxo de buscar os agendamentos (com offline)
    // busca na API -> se retornar erro devolve os agendamentos offline + flag avisando o offline -> se não retorna os dados remotos e salva no SQLite
    // try {
    //   final response = await remoteApi.get('/appointments'); 
    //   final list = (response as List).map((e) => AppointmentModel.fromJson(e)).toList();
      
    //   await localDb.save(list); 
      
    //   return list;
    // } catch (e) {
    //   return await localDb.getAll();
    // }

      // dados mockados com o delay (pra testar o shader do widget)
      await Future.delayed(const Duration(seconds: 1));    return [
      AppointmentModel(
        id: 1,
        serviceType: 'Encanador',
        user: 'João Vitor',
        value: 15000, 
        scheduleDate: DateTime.now().add(const Duration(days: 2, hours: 10)),
        requestDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppointmentModel(
        id: 2,
        serviceType: 'Eletricista',
        user: 'João Vitor',
        value: 22050, 
        scheduleDate: DateTime.now().add(const Duration(days: 5, hours: 14)),
        requestDate: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      AppointmentModel(
        id: 3,
        serviceType: 'Mecânico',
        user: 'João Vitor',
        value: 8500, 
        scheduleDate: DateTime.now().add(const Duration(days: 1, hours: 9)),
        requestDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}