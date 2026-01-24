extension CapitalExtension on String {
  String capitalise() {
    if (this.length == 1) {
      return this;
    }

    return this[0].toUpperCase() + this.substring(1);
  }
}