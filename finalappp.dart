import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';

List<CameraDescription> _cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light(),
    home: CheckIn(),
  ));
}

// ---------------- Visitor Model ----------------
class Visitor {
  final String name;
  final Uint8List? imageBytes;
  Visitor(this.name, this.imageBytes);
}

// ---------------- CheckIn Page ----------------
class CheckIn extends StatefulWidget {
  const CheckIn({super.key});
  @override
  State<CheckIn> createState() => _CheckInState();
}

class _CheckInState extends State<CheckIn> {
  String? selectedRole;
  void selectRole(String role) {
    setState(() {
      selectedRole = role;
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(height: 120),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.mulish(
                    fontSize: 36,
                     fontWeight: FontWeight.bold
                     ),
                  children: [
                    TextSpan(text: 'Set ',
                     style: TextStyle(color: textColor)
                     ),
                    TextSpan(text: 'Your ',
                     style: TextStyle(color: Colors.blue.shade400)
                     ),
                    TextSpan(text: 'Role',
                     style: TextStyle(color: textColor)
                     ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Select your role to proceed.\nAdministrator manages access, Gatekeeper handles visitor requests.',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                 fontWeight: FontWeight.bold,
                  color: theme.hintColor
                  ),
                textAlign: TextAlign.center,
              ),
              buildRoleButton(
                icon: Icons.person,
                label: 'Admin',
                isSelected: selectedRole == 'Admin',
                onTap: () => selectRole('Admin'),
              ),
              SizedBox(height: 30),
              buildRoleButton( 
                icon: Icons.verified_user,
                label: 'Gatekeeper',
                isSelected: selectedRole == 'Gatekeeper',
                onTap: () => selectRole('Gatekeeper'),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRole == null
                      ? null
                      : () {
                          if (selectedRole == 'Gatekeeper') {
                            Navigator.push(context,
                             MaterialPageRoute(
                              builder: (context) => FirstPage()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Admin navigation not implemented yet.')
                                ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedRole == null ?
                     theme.disabledColor : Colors.blue.shade400,
                    padding: EdgeInsets.symmetric(
                      vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Confirm', 
                  style: GoogleFonts.mulish(
                    color: Colors.white,
                     fontSize: 18,
                      fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRoleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final blue = Colors.blue.shade400;
    return GestureDetector(
      onTap: () => selectRole(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? blue.withOpacity(0.1) : theme.cardColor,
          border: Border.all(
            color: isSelected 
            ? blue : blue.withOpacity(0.6),
             width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(2, 4),
            )
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: blue,
                 shape: BoxShape.circle
                 ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Text(label,
               style: GoogleFonts.mulish(
                fontSize: 20,
                 fontWeight: FontWeight.bold
                 )
                 )
                 ),
            Icon(
              isSelected 
                ? Icons.check_circle 
                : Icons.radio_button_unchecked,
                color: isSelected 
                ? blue : theme.disabledColor
                ),
          ],
        ),
      ),
    );
  }
}

// ---------------- First Page (Visitor List) ----------------
class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  List<Visitor> visitors = [];
  List<Visitor> filteredVisitors = [];
  bool isSearching = false;
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    List<Visitor> displayList = isSearching ? filteredVisitors : visitors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        title: Text("List of Check-In Visitor", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.search, color: Colors.black),
                onPressed: () {
                  final searchController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Search Username"),
                      content: TextField(
                        controller: searchController,
                         decoration: InputDecoration(
                          hintText: "Enter username"
                          )
                          ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                           child: Text("Cancel")
                           ),
                        TextButton(
                          onPressed: () {
                            String query = searchController.text.trim();
                            final found = visitors.where((v) => v.name.toLowerCase().contains(query.toLowerCase())).toList();

                           if(found.isNotEmpty)
                           {
                             setState(() 
                             {
                            filteredVisitors = found;
                            isSearching = true;
                             }
                             );
                            ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                             content: Text("Visitor '$query' found."),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                            );
                           }
                           else{
                             setState(() {
                              isSearching = false;
                              }
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Visitor '$query' Not found."),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                            Navigator.pop(context);
                          },
                          child: Text("Search"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (isSearching)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.red),
              onPressed: () => setState(() => isSearching = false),
            ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(12),
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final visitor = displayList[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: visitor.imageBytes != null
                    ? MemoryImage(visitor.imageBytes!)
                    : AssetImage('assets/default_user.png') as ImageProvider,
              ),
              title: Text(visitor.name),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade400),
                onPressed: () {
                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
                                      content: Text("Are you sure you want to checkout '${visitor.name}'?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text("No"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              visitors.remove(visitor);
                                            }
                                          );
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text("${visitor.name} Check Out Successfully !!"),
                                    backgroundColor: Colors.green.shade500,
                                ));
                              },
                            child: Text('Yes'),
                          ),
                        ],
                      ),
                    );
                  },
                child: Text("Check Out", style: TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade400,
        child: Icon(Icons.add),
        onPressed: () async {
         showRoleDialog(
    context: context,
    selectedRole: null,
    onSelected: (String role) async {
      if (role == 'Visitor') {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CheckinMaterial()),
        );

        if (result != null && result is Visitor) {
          setState(() {
            visitors.add(result);
            
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Visitor '${result.name}' added to check-in list"),
              backgroundColor: Colors.green.shade500,
            ),
          );
        }
      } else if (role == 'Employee') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CheckinMaterial()),
        );
      }
    },
  );
  },
  ),
  );
}
}

// ---------------- Check-in Form Page ----------------
class CheckinMaterial extends StatefulWidget {
  @override
  State<CheckinMaterial> createState() => _CheckinMaterialState();
}

class _CheckinMaterialState extends State<CheckinMaterial> {
  late String date;
  late String time;
  bool isRequestAccepted = false;
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final placeController = TextEditingController();
  final purposeController = TextEditingController();
  final tomeetController = TextEditingController();
  CameraController? _controller;
  Uint8List? _imageBytes;
  bool _showCamera = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    date = DateFormat('yyyy-MM-dd').format(now);
    time = DateFormat('hh:mm a').format(now);
    _initCamera();
  }

  Future<void> _initCamera() async => _cameras = await availableCameras();

  Future<void> _initializeCamera() async {
    _controller = CameraController(_cameras.first, ResolutionPreset.medium);
    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    try {
      final picture = await _controller!.takePicture();
      final bytes = await picture.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _showCamera = false;
      });
      _controller?.dispose();
      _controller = null;
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        title: Text("Check In Page", style: GoogleFonts.mulish()),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Enter The Details",
                    style: GoogleFonts.mulish(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 10),
                _buildTextField("Name", "Name", nameController, icon: Icons.person),
                SizedBox(height: 15),
                _buildTextField("Mobile", "Phone no", mobileController,
                keyboardType: TextInputType.phone, icon: Icons.phone,maxLength: 10,inputFormatters: [FilteringTextInputFormatter.digitsOnly],),
                SizedBox(height: 15),
                _buildTextField("Place", "Place", placeController, icon: Icons.place),
                SizedBox(height: 15),
                _buildTextField("To Meet", "To Meet", tomeetController, icon: Icons.people),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildReadOnlyField("Date", date)),
                    SizedBox(width: 10),
                    Expanded(child: _buildReadOnlyField("Time", time)),
                  ],
                ),
                SizedBox(height: 15),
                _buildTextField("Purpose", "Purpose", purposeController, icon: Icons.info),
                SizedBox(height: 30),
              Text("Visitor Photo", style: GoogleFonts.mulish(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                GestureDetector(
                  onTap: () async {
                    setState(() => _showCamera = true);
                    await _initializeCamera();
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                    child: _imageBytes == null ? Icon(Icons.camera_alt, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Text("Tap to open camera", style: TextStyle(fontSize: 16))
              ]),
              if (_showCamera && _controller != null && _controller!.value.isInitialized)
                Column(children: [
                  const SizedBox(height: 20),
                  AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: CameraPreview(_controller!)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: Icon(Icons.camera),
                    label: Text("Take Picture"),
                  ),
                ]),
              SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => isRequestAccepted = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Request sent!'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        minimumSize: Size(150, 50),
                      ),
                      child: Text('Request'),
                    ),
                    ElevatedButton(
                      onPressed: isRequestAccepted
                          ? () => Navigator.pop(context, Visitor(nameController.text.trim(), _imageBytes))
                          : null,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRequestAccepted ? Colors.teal : Colors.grey,
                        minimumSize: Size(130, 50),
                      ),
                      child: Text('Check-in', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

 Widget _buildTextField(String label, String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, IconData? icon, int? maxLength, List<TextInputFormatter>? inputFormatters,}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.mulish(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
           maxLength: maxLength, 
          inputFormatters: inputFormatters, 
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade200,
            prefixIcon: icon != null ? Icon(icon, color: Colors.blue.shade400) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          if (label == 'Mobile' && value.trim().length != 10) {
            return 'Mobile number must be 10 digits';
          }
          return null;
        },
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.mulish(fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(height: 5),
        TextFormField(
          initialValue: value,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
void showRoleDialog({
  required BuildContext context,
  required String? selectedRole,
  required Function(String) onSelected,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 320,
          height: 350,
          child: Column(
            children: [
              const Spacer(),
              _buildDialogRoleButton(
                context,
                icon: Icons.work_outline,
                label: 'Employee',
                isSelected: selectedRole == 'Employee',
                onTap: () {
                  Navigator.pop(context);
                  onSelected('Employee');
                },
              ),
              const SizedBox(height: 30),
              _buildDialogRoleButton(
                context,
                icon: Icons.qr_code_scanner,
                label: 'Visitor',
                isSelected: selectedRole == 'Visitor',
                onTap: () {
                  Navigator.pop(context);
                  onSelected('Visitor');
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      );
    },
  );
}
Widget _buildDialogRoleButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  final blue = Colors.blue.shade400;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? blue.withOpacity(0.1) : Colors.grey.shade100,
        border: Border.all(
          color: isSelected ? blue : blue.withOpacity(0.6),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: blue, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.mulish(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSelected ? blue : Colors.grey,
            size: 24,
          ),
        ],
      ),
    ),
  );
}