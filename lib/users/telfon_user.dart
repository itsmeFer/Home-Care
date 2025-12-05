import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class CallScreenPage extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userAvatar;
  final String phoneNumber;

  const CallScreenPage({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userAvatar,
    required this.phoneNumber,
  });

  @override
  State<CallScreenPage> createState() => _CallScreenPageState();
}

class _CallScreenPageState extends State<CallScreenPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _avatarController;
  late AnimationController _buttonsController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _avatarAnimation;
  late Animation<double> _buttonsAnimation;

  CallState _callState = CallState.dialing;
  Timer? _callTimer;
  Timer? _vibrationTimer;
  Duration _callDuration = Duration.zero;
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _avatarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _avatarController,
      curve: Curves.elasticOut,
    ));

    _buttonsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOutBack,
    ));

    _startCall();
  }

  void _startCall() {
    _avatarController.forward();
    _pulseController.repeat(reverse: true);
    
    // Start ringing vibration pattern
    _startRingingVibration();

    // Simulate connecting after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _stopRingingVibration();
        _playConnectVibration();
        setState(() => _callState = CallState.connected);
        _startCallTimer();
        _buttonsController.forward();
        HapticFeedback.lightImpact();
      }
    });
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration = Duration(seconds: timer.tick);
        });
      }
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    _pulseController.stop();
    _stopRingingVibration();
    _playEndCallVibration();
    setState(() => _callState = CallState.ended);
    
    HapticFeedback.mediumImpact();
    
    // Close screen after brief delay
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _playClickVibration();
    HapticFeedback.selectionClick();
  }

  void _toggleSpeaker() {
    setState(() => _isSpeaker = !_isSpeaker);
    _playClickVibration();
    HapticFeedback.selectionClick();
  }
  
  // Vibration methods
  void _startRingingVibration() {
    // Pattern: [wait, vibrate, wait, vibrate] in milliseconds
    // Repeat pattern every 2 seconds
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      Vibration.vibrate(
        pattern: [0, 200, 400, 200],
        intensities: [0, 128, 0, 128],
      );
    });
  }
  
  void _stopRingingVibration() {
    _vibrationTimer?.cancel();
    Vibration.cancel();
  }
  
  void _playConnectVibration() {
    Vibration.vibrate(duration: 200, amplitude: 200);
  }
  
  void _playEndCallVibration() {
    Vibration.vibrate(
      pattern: [0, 150, 100, 150],
      intensities: [0, 255, 0, 255],
    );
  }
  
  void _playClickVibration() {
    Vibration.vibrate(duration: 50, amplitude: 128);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _vibrationTimer?.cancel();
    _pulseController.dispose();
    _avatarController.dispose();
    _buttonsController.dispose();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0BA5A7),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0BA5A7),
              const Color(0xFF088088),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildCallContent(),
              ),
              _buildCallControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Home Care Call',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallContent() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 300,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Call Status
            Text(
              _getCallStatusText(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
        
            if (_callState == CallState.connected) ...[
              const SizedBox(height: 8),
              Text(
                _formatDuration(_callDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Avatar with pulse animation
            AnimatedBuilder(
              animation: _avatarAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _avatarAnimation.value,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _callState == CallState.dialing ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: widget.userAvatar.isNotEmpty
                                ? Image.network(
                                    widget.userAvatar,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
                                  )
                                : _buildAvatarFallback(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // User Info
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 6),
            
            Text(
              widget.userRole,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.phoneNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (_callState == CallState.connected) ...[
              const SizedBox(height: 20),
              _buildConnectionStatus(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 80,
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Terhubung',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    if (_callState == CallState.ended) {
      return const SizedBox(height: 100);
    }

    return AnimatedBuilder(
      animation: _buttonsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _buttonsAnimation.value)),
          child: Opacity(
            opacity: _buttonsAnimation.value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  if (_callState == CallState.connected) ...[
                    // Secondary controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSecondaryButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          isActive: _isMuted,
                          onTap: _toggleMute,
                        ),
                        _buildSecondaryButton(
                          icon: Icons.dialpad,
                          isActive: false,
                          onTap: () => _showDialpad(),
                        ),
                        _buildSecondaryButton(
                          icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                          isActive: _isSpeaker,
                          onTap: _toggleSpeaker,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                  
                  // Main end call button
                  _buildEndCallButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: _endCall,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _showDialpad() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Dialpad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final dialpadNumbers = [
                    '1', '2', '3',
                    '4', '5', '6', 
                    '7', '8', '9',
                    '*', '0', '#'
                  ];
                  
                  return GestureDetector(
                    onTap: () {
                      _playClickVibration();
                      HapticFeedback.selectionClick();
                      // Add dialpad functionality here
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          dialpadNumbers[index],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCallStatusText() {
    switch (_callState) {
      case CallState.dialing:
        return 'Menghubungi...';
      case CallState.connected:
        return 'Terhubung';
      case CallState.ended:
        return 'Panggilan Berakhir';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

enum CallState { dialing, connected, ended }