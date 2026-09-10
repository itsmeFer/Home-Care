import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'booking_addons_step.dart';
import 'booking_details_step.dart';
import 'booking_location_step.dart';
import 'booking_schedule_step.dart';
import 'booking_summary_step.dart';

/// Container that renders the appropriate step in the booking wizard.
class BookingStepContent extends StatelessWidget {
  final int currentStep;
  final GlobalKey<FormState> formKey;
  final TextEditingController tanggalController;
  final TextEditingController jamController;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final TextEditingController alamatController;
  final TextEditingController kotaController;
  final TextEditingController kecamatanController;
  final bool isLoadingProfile;
  final VoidCallback onUseProfile;
  final TextEditingController catatanController;
  final int qty;
  final VoidCallback onIncrementQty;
  final VoidCallback onDecrementQty;
  final Uint8List? kondisiPasienBytes;
  final VoidCallback onPickImage;
  final InputDecoration Function({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    bool alignLabelWithHint,
  }) inputDecoration;
  final bool isLoadingAddons;
  final List<Addon> availableAddons;
  final List<Addon> selectedAddons;
  final ValueChanged<Addon> onToggleAddon;
  final ValueChanged<Addon> onIncrementAddon;
  final ValueChanged<Addon> onDecrementAddon;
  final Layanan layanan;
  final double total;

  const BookingStepContent({
    super.key,
    required this.currentStep,
    required this.formKey,
    required this.tanggalController,
    required this.jamController,
    required this.onPickDate,
    required this.onPickTime,
    required this.alamatController,
    required this.kotaController,
    required this.kecamatanController,
    required this.isLoadingProfile,
    required this.onUseProfile,
    required this.catatanController,
    required this.qty,
    required this.onIncrementQty,
    required this.onDecrementQty,
    required this.kondisiPasienBytes,
    required this.onPickImage,
    required this.inputDecoration,
    required this.isLoadingAddons,
    required this.availableAddons,
    required this.selectedAddons,
    required this.onToggleAddon,
    required this.onIncrementAddon,
    required this.onDecrementAddon,
    required this.layanan,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          if (currentStep == 0)
            BookingScheduleStep(
              tanggalController: tanggalController,
              jamController: jamController,
              onPickDate: onPickDate,
              onPickTime: onPickTime,
            ),
          if (currentStep == 1)
            BookingLocationStep(
              alamatController: alamatController,
              kotaController: kotaController,
              kecamatanController: kecamatanController,
              isLoadingProfile: isLoadingProfile,
              onUseProfile: onUseProfile,
            ),
          if (currentStep == 2)
            BookingDetailsStep(
              catatanController: catatanController,
              qty: qty,
              onIncrementQty: onIncrementQty,
              onDecrementQty: onDecrementQty,
              kondisiPasienBytes: kondisiPasienBytes,
              onPickImage: onPickImage,
              inputDecoration: inputDecoration,
            ),
          if (currentStep == 3)
            BookingAddonsStep(
              isLoadingAddons: isLoadingAddons,
              availableAddons: availableAddons,
              selectedAddons: selectedAddons,
              onToggleAddon: onToggleAddon,
              onIncrementAddon: onIncrementAddon,
              onDecrementAddon: onDecrementAddon,
              formatRupiah: AppFormatters.currency,
            ),
          if (currentStep == 4)
            BookingSummaryStep(
              namaLayanan: layanan.namaLayanan,
              hargaLayanan: layanan.hargaFix,
              tanggal: tanggalController.text,
              jam: jamController.text,
              lokasi: kotaController.text,
              qty: qty,
              selectedAddons: selectedAddons,
              total: total,
              formatRupiah: AppFormatters.currency,
            ),
        ],
      ),
    );
  }
}
