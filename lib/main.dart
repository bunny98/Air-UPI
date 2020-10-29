import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upi_india/upi_india.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:progress_indicators/progress_indicators.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: Scaffold(
        // appBar: AppBar(
        //   title: Text('Air Upi',
        //       style: GoogleFonts.lobster(fontSize: 30, color: Colors.black)),
        // ),
        resizeToAvoidBottomPadding: false,
        body: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _locationpermission = false;
  bool _isAdvertiser = false;
  bool _hasReceivedId = false;
  bool _isDiscovering = false;
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  String _receivedUPI = '';
  String _enteredUPI = '';
  List<String> cId = [];
  Future _transaction;

  Future askPermission() async {
    if (!await Nearby().checkLocationPermission()) {
      await Nearby().askLocationPermission();
    }
    _locationpermission = await Nearby().checkLocationPermission();
    if (!_locationpermission) askPermission();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      askPermission();
    });
  }

  Future<String> initiateTransaction(String app) async {
    UpiIndia upi;
    String response;
    try {
      upi = new UpiIndia(
        app: app,
        receiverUpiId: _receivedUPI,
        receiverName: 'Received UPI',
        transactionRefId: 'TestingId',
        transactionNote: 'Testing sending 1 rs',
        amount: 1.00,
      );
      response = await upi.startTransaction();
    } catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }

    return response;
  }

  void _askUPIid() {
    _enteredUPI = "";
    showModalBottomSheet(
        context: context,
        builder: (builder) => Card(
              child: Column(children: [
                TextField(
                  onChanged: (text) {
                    _enteredUPI = text.trim();
                  },
                  style: GoogleFonts.quicksand(),
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter UPI ID to Broadcast'),
                ),
                FlatButton(
                    onPressed: () {
                      print(_enteredUPI.length);
                      if (_enteredUPI.length > 0) {
                        _startAdvertising(_enteredUPI);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Icon(Icons.done),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.red)))
              ]),
            ));
  }

  Future<void> _startAdvertising(String upi) async {
    try {
      bool a = await Nearby().startAdvertising(userName, strategy,
          onConnectionInitiated: onConnectionInit,
          onConnectionResult: (id, status) {
        // showSnackbar('Advertiser Connected to ' + id.toString());
        Nearby().sendBytesPayload(id, Uint8List.fromList(upi.codeUnits));
        // showSnackbar('Sending: $upi');
      }, onDisconnected: (id) {
        cId.removeWhere((item) => item == id);
        showSnackbar('Disconnected Device ID:' + id);
      });
      showSnackbar('Advertising UPI ID');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
    });
    try {
      await Nearby().startDiscovery(userName, strategy,
          onEndpointFound: (id, name, serviceId) {
            // showSnackbar(
            //     'Advertiser found: ' + name + ' requesting connection!');
            Nearby().requestConnection(userName, id,
                onConnectionInitiated: (id, info) => onConnectionInit(id, info),
                onConnectionResult: (id, status) {
                  // showSnackbar('Connected to Advertiser: ' + id.toString());
                },
                onDisconnected: (id) {
                  cId.removeWhere((item) => item == id);
                  // showSnackbar('Broadcasting node terminated!');
                });
          },
          onEndpointLost: (id) => showSnackbar('Lost Endpoint: ' + id));
      showSnackbar('Discovering Advertisers...');
    } catch (e) {
      showSnackbar(e);
    }
  }

  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Colors.blue, Colors.red])),
      ),
      Positioned(
        height: MediaQuery.of(context).size.height,
        child: Opacity(
            opacity: 0.2,
            child: Image.asset(
              'bg.png',
              fit: BoxFit.cover,
            )),
      ),
      Positioned(
          top: 40,
          child: Text(
            "AIR UPI",
            style: GoogleFonts.asul(color: Colors.white, fontSize: 40),
          )),
      Container(
        // color: Colors.amber,
        // padding: EdgeInsets.only(top: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
              flex: 1,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  height: 20,
                ),
                Center(
                    child: Wrap(
                  children: <Widget>[
                    GestureDetector(
                      child: Card(
                        elevation: 5,
                        color: Colors.greenAccent,
                        child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text('Advertise UPI ID',
                                style: GoogleFonts.quicksand(
                                    color: Colors.black, fontSize: 18))),
                      ),
                      onTap: () {
                        setState(() {
                          _isAdvertiser = true;
                          _hasReceivedId = false;
                          _receivedUPI = null;
                        });
                        _askUPIid();
                      },
                    ),
                    GestureDetector(
                      child: Card(
                        elevation: 5,
                        color: Colors.redAccent,
                        child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text('Stop Advertising',
                                style: GoogleFonts.quicksand(
                                  color: Colors.white,
                                  fontSize: 18,
                                ))),
                      ),
                      onTap: () async {
                        await Nearby().stopAdvertising();
                        setState(() {
                          _isAdvertiser = false;
                        });
                        showSnackbar('Stopped Advertising');
                      },
                    ),
                  ],
                )),
                SizedBox(
                  height: 10,
                ),
                if (!_isAdvertiser)
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white)),
                    child: Center(
                      child: Text(
                        "OR",
                        style: GoogleFonts.asul(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                SizedBox(
                  height: 10,
                ),
                if (!_isAdvertiser)
                  Center(
                    child: Wrap(children: <Widget>[
                      GestureDetector(
                        child: Card(
                          elevation: 5,
                          color: Colors.yellowAccent,
                          child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Text('Start Discovery',
                                  style: GoogleFonts.quicksand(
                                      color: Colors.black, fontSize: 18))),
                        ),
                        onTap: () {
                          setState(() {
                            _isAdvertiser = false;
                            _hasReceivedId = false;
                          });
                          _startDiscovery();
                        },
                      ),
                      GestureDetector(
                        child: Card(
                          elevation: 5,
                          color: Colors.pinkAccent,
                          child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Text('Stop Discovery',
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ))),
                        ),
                        onTap: () async {
                          await Nearby().stopDiscovery();
                          setState(() {
                            _isDiscovering = false;
                          });
                          showSnackbar('Stopped Discovering');
                        },
                      ),
                    ]),
                  ),
                SizedBox(
                  height: 20,
                ),
                if (_isAdvertiser)
                  Center(
                    child: GestureDetector(
                      child: Card(
                        elevation: 5,
                        color: Colors.orangeAccent,
                        child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text('Disconnect All Devices',
                                style: GoogleFonts.quicksand(
                                    color: Colors.black, fontSize: 18))),
                      ),
                      onTap: () async {
                        await Nearby().stopAllEndpoints();
                        showSnackbar('Stopped All Endpoints');
                      },
                    ),
                  ),
                SizedBox(
                  height: 20,
                ),
                if (_isAdvertiser)
                  Text('Broadcasting UPI...',
                      style: GoogleFonts.quicksand(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 10,
                ),
                if (_isAdvertiser)
                  HeartbeatProgressIndicator(
                    child: Icon(
                      Icons.whatshot,
                      color: Colors.white,
                    ),
                  ),
                if (_isDiscovering) Center(child: CircularProgressIndicator()),
                if (_hasReceivedId)
                  Center(
                    child: GestureDetector(
                      child: Card(
                        elevation: 5,
                        color: Colors.blueAccent,
                        child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text('Pay to: $_receivedUPI',
                                style: GoogleFonts.quicksand(
                                    color: Colors.white, fontSize: 18))),
                      ),
                      onTap: () {
                        _transaction =
                            initiateTransaction(UpiIndiaApps.GooglePay);
                        setState(() {});
                      },
                    ),
                  )
              ])),
          SizedBox(
            height: 20,
          ),
          if (_transaction != null)
            Flexible(
              flex: 1,
              child: FutureBuilder(
                future: _transaction,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      snapshot.data == null)
                    return Text(' ');
                  else {
                    switch (snapshot.data.toString()) {
                      case UpiIndiaResponseError.APP_NOT_INSTALLED:
                        return Text(
                          'App not installed.',
                        );
                        break;
                      case UpiIndiaResponseError.INVALID_PARAMETERS:
                        return Text(
                          'Requested payment is invalid.',
                        );
                        break;
                      case UpiIndiaResponseError.USER_CANCELLED:
                        return Text(
                          'It seems like you cancelled the transaction.',
                        );
                        break;
                      case UpiIndiaResponseError.NULL_RESPONSE:
                        return Text(
                          'No data received',
                        );
                        break;
                      default:
                        UpiIndiaResponse _upiResponse;
                        _upiResponse = UpiIndiaResponse(snapshot.data);
                        String txnId = _upiResponse.transactionId;
                        String resCode = _upiResponse.responseCode;
                        String txnRef = _upiResponse.transactionRefId;
                        String status = _upiResponse.status;
                        String approvalRef = _upiResponse.approvalRefNo;
                        return Stack(alignment: Alignment.center, children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Transaction Id: $txnId',
                                ),
                                Text('Response Code: $resCode'),
                                Text('Reference Id: $txnRef'),
                                Text('Status: $status'),
                                Text('Approval No: $approvalRef'),
                                FlatButton(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                        side: BorderSide(color: Colors.red)),
                                    onPressed: () {
                                      setState(() {
                                        _transaction = null;
                                      });
                                    },
                                    child: Text("Close"))
                              ],
                            ),
                          ),
                        ]);
                    }
                  }
                },
              ),
            )
        ]),
      ),
    ]);
  }

  void showSnackbar(dynamic a) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    cId.add(id);
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String str = String.fromCharCodes(payload.bytes);
          // showSnackbar(endid + ": " + str);
          if (!_isAdvertiser) {
            setState(() {
              _receivedUPI = str;
              _hasReceivedId = true;
              _isDiscovering = false;
            });
          }
          // showSnackbar('Received UPI ID: ' + str + ' From ID: ' + endid);
        }
      },
      onPayloadTransferUpdate: (endid, payloadTransferUpdate) async {
        if (payloadTransferUpdate.status == PayloadStatus.IN_PROGRRESS) {
          print(payloadTransferUpdate.bytesTransferred);
        } else if (payloadTransferUpdate.status == PayloadStatus.FAILURE) {
          print("failed");
          showSnackbar(endid + ": FAILED to transfer file");
        } else if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
          // showSnackbar(
          //     "success, total bytes = ${payloadTransferUpdate.totalBytes}");
          if (!_isAdvertiser) {
            await Nearby().stopAllEndpoints();
            await Nearby().stopDiscovery();
          }
        }
      },
    );
  }
}
