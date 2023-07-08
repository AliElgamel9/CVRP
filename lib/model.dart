enum RoleType {
  CUSTOMER,
  DRIVER,
  SUPPLIER,
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final RoleType roleType;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.roleType,
  });

  UserModel.empty()
      : id = 0,
        name = '',
        email = '',
        phoneNumber = '',
        roleType = RoleType.CUSTOMER;
}

class Customer extends UserModel {
  final int serviceId;
  final double latitude;
  final double longitude;
  final String locationName;

  Customer({
    required this.serviceId,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required super.id,
    required super.name,
    required super.email,
    required super.phoneNumber,
    required super.roleType,
  });

  Customer.empty()
      : serviceId = 0,
        latitude = 0.0,
        longitude = 0.0,
        locationName = '',
        super.empty();
}

class Supplier extends UserModel {
  final int orderId;
  final List<String> myCustomersId;
  final List<String> myDriversId;
  final double latitude;
  final double longitude;

  Supplier({
    required this.orderId,
    required this.myCustomersId,
    required this.myDriversId,
    required this.latitude,
    required this.longitude,
    required super.id,
    required super.name,
    required super.email,
    required super.phoneNumber,
    required super.roleType,
  });

  Supplier.empty()
      : orderId = 0,
        myCustomersId = [],
        myDriversId = [],
        latitude = 0.0,
        longitude = 0.0,
        super.empty();

  Supplier.clone(
    Supplier supplier, {
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    RoleType? roleType,
    int? orderId,
    List<String>? myCustomersId,
    List<String>? myDriversId,
    double? latitude,
    double? longitude,
  })  : orderId = orderId ?? supplier.orderId,
        myCustomersId = myCustomersId ?? supplier.myCustomersId,
        myDriversId = myDriversId ?? supplier.myDriversId,
        latitude = latitude ?? supplier.latitude,
        longitude = longitude ?? supplier.longitude,
        super(
          id: id ?? supplier.id,
          name: name ?? supplier.name,
          email: email ?? supplier.email,
          phoneNumber: phoneNumber ?? supplier.phoneNumber,
          roleType: roleType ?? supplier.roleType,
        );
}

class Driver extends UserModel {
  final int orderId;
  final int serviceId;
  final int remainingServices;
  final int totalServices;
  final String carLicense;
  final int carColor;

  Driver({
    required this.orderId,
    required this.serviceId,
    required this.remainingServices,
    required this.totalServices,
    required this.carLicense,
    required this.carColor,
    required super.id,
    required super.name,
    required super.email,
    required super.phoneNumber,
    required super.roleType,
  });

  Driver.empty()
      : orderId = 0,
        serviceId = 0,
        remainingServices = 0,
        totalServices = 0,
        carLicense = '',
        carColor = 0,
        super.empty();

  Driver.clone(
    Driver driver, {
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    RoleType? roleType,
    int? orderId,
    int? serviceId,
    int? remainingServices,
    int? totalOrders,
    String? carLicense,
    int? carColor,
  })  : orderId = orderId ?? driver.orderId,
        serviceId = serviceId ?? driver.serviceId,
        remainingServices = remainingServices ?? driver.remainingServices,
        totalServices = totalOrders ?? driver.totalServices,
        carLicense = carLicense ?? driver.carLicense,
        carColor = carColor ?? driver.carColor,
        super(
          id: id ?? driver.id,
          name: name ?? driver.name,
          email: email ?? driver.email,
          phoneNumber: phoneNumber ?? driver.phoneNumber,
          roleType: roleType ?? driver.roleType,
        );
}

class OrderModel {
  final int id;
  final int numberOfServices;
  final List<int> servicesId;
  final int numberOfVehicles;
  final List<int> vehiclesCapacity;
  final List<int> driversId;

  OrderModel({
    required this.id,
    required this.numberOfServices,
    required this.servicesId,
    required this.numberOfVehicles,
    required this.vehiclesCapacity,
    required this.driversId,
  });

  OrderModel.empty()
      : id = 0,
        numberOfServices = 0,
        servicesId = [],
        numberOfVehicles = 0,
        vehiclesCapacity = [],
        driversId = [];
}

class OrderExtraModel {
  final List<int> customersId;
  final List<int> minDemands;
  final List<int> maxDemands;

  OrderExtraModel({
    required this.customersId,
    required this.minDemands,
    required this.maxDemands,
  });
}

class ServiceModel {
  final int id;
  final int demand;
  final String locationName;
  final String expectedArrivalTime;
  final int driverId;
  final int customerId;
  final bool isLocked;
  final bool isDelivered;

  ServiceModel({
    required this.id,
    required this.demand,
    required this.locationName,
    required this.expectedArrivalTime,
    required this.driverId,
    required this.customerId,
    required this.isLocked,
    required this.isDelivered,
  });

  ServiceModel.empty()
      : id = 0,
        demand = 0,
        locationName = '',
        expectedArrivalTime = '',
        driverId = 0,
        customerId = 0,
        isLocked = false,
        isDelivered = false;
}

class OrderModelFullData {
  final int id;
  final int numberOfServices;
  final int numberOfVehicles;
  final List<int> customersId;
  List<bool> isServicesLocked;
  final List<int> newCustomersId;
  final List<int> deletedCustomersId;
  final List<int> driversId;
  final List<int> maxDemands;
  final List<int> minDemands;
  final List<int> newMaxDemands;
  final List<int> newMinDemands;
  final List<int> vehiclesCapacity;
  final List<int> servicesId;
  final bool isLocked;

  OrderModelFullData({
    required this.id,
    required this.numberOfServices,
    required this.numberOfVehicles,
    required this.customersId,
    required this.isServicesLocked,
    required this.newCustomersId,
    required this.deletedCustomersId,
    required this.driversId,
    required this.maxDemands,
    required this.minDemands,
    required this.newMaxDemands,
    required this.newMinDemands,
    required this.vehiclesCapacity,
    required this.servicesId,
    required this.isLocked,
  });

  OrderModelFullData.empty()
      : id = 0,
        numberOfServices = 0,
        numberOfVehicles = 0,
        customersId = [],
        isServicesLocked = [],
        newCustomersId = [],
        deletedCustomersId = [],
        driversId = [],
        maxDemands = [],
        minDemands = [],
        newMaxDemands = [],
        newMinDemands = [],
        vehiclesCapacity = [],
        servicesId = [],
        isLocked = false;

  OrderModelFullData.clone(
    OrderModelFullData order, {
    int? id,
    int? numberOfServices,
    int? numberOfVehicles,
    List<int>? customersId,
    List<bool>? isCustomersLocked,
    List<int>? newCustomersId,
    List<int>? deletedCustomersId,
    List<int>? driversId,
    List<int>? maxDemands,
    List<int>? minDemands,
    List<int>? newMaxDemand,
    List<int>? newMinDemand,
    List<int>? vehiclesCapacity,
    List<int>? servicesId,
    bool? isLocked,
  })  : id = id ?? order.id,
        numberOfServices = numberOfServices ?? order.numberOfServices,
        numberOfVehicles = numberOfVehicles ?? order.numberOfVehicles,
        customersId = customersId ?? order.customersId,
        isServicesLocked = isCustomersLocked ?? order.isServicesLocked,
        newCustomersId = newCustomersId ?? order.newCustomersId,
        deletedCustomersId = deletedCustomersId ?? order.deletedCustomersId,
        driversId = driversId ?? order.driversId,
        maxDemands = maxDemands ?? order.maxDemands,
        minDemands = minDemands ?? order.minDemands,
        newMaxDemands = newMaxDemand ?? order.newMaxDemands,
        newMinDemands = newMinDemand ?? order.newMinDemands,
        vehiclesCapacity = vehiclesCapacity ?? order.vehiclesCapacity,
        servicesId = servicesId ?? order.servicesId,
        isLocked = isLocked ?? order.isLocked;
}

class DriverTrackingModel {
  final int driverId;
  final String driverName;
  final String driverPhoneNumber;
  final List<int> servicesId;
  final List<String> customersName;
  final List<int> demands;
  final int currentServiceIndex;
  final double customerLatitude;
  final double customerLongitude;
  final String expectedArrivalTime;
  final String locationName;

  DriverTrackingModel({
    required this.driverId,
    required this.driverName,
    required this.driverPhoneNumber,
    required this.servicesId,
    required this.customersName,
    required this.demands,
    required this.currentServiceIndex,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.expectedArrivalTime,
    required this.locationName,
  });
}
