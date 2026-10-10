
enum VillageTime {
  morning,
  day,
  evening,
  night,
}

class VillageTimeService {
  static VillageTime getCurrentTime() {
    return fromHour(DateTime.now().hour);
  }

  static VillageTime fromHour(int hour) {
    if (hour >= 5 && hour < 10) {
      return VillageTime.morning;
    }

    if (hour >= 10 && hour < 18) {
      return VillageTime.day;
    }

    if (hour >= 18 && hour < 22) {
      return VillageTime.evening;
    }

    return VillageTime.night;
  }

  static String imageFor(VillageTime time) {
    switch (time) {
      case VillageTime.morning:
        return 'assets/images/village/village_morning.png';
      case VillageTime.day:
        return 'assets/images/village/village_day.png';
      case VillageTime.evening:
        return 'assets/images/village/village_evening.png';
      case VillageTime.night:
        return 'assets/images/village/village_night.png';
    }
  }
}
