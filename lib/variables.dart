import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// Base URL and Login related
Map? baseurlresponsebody;
Map? baseurlresult;
TextEditingController loginmobilenumber = TextEditingController();
TextEditingController loginpassword = TextEditingController();

Map? loginresult;
Map? loginresponsebody;
Map<String, dynamic>? globalloginData;
bool isoffline = false;

// Production and Project related
String? productionHouse;
String? projectId;
String? managerName;
String? designation;
String? registeredMovie;
int? productionTypeId;
List<dynamic> movieProjects = [];

// Session and User related
String? vcid;
String? vsid;
String? ProfileImage;
String? vpid;
int? vmid;
int? vuid;
int? mtypeId;
int? vmTypeId;
int? vpoid;
int? vbpid;
int? vsubid;
int? vpidpo;
int? vpidbp;
int? unitid;
String? companyName;
String? email;
String? unitName;
String? idcardurl;
bool? driver;
int? callsheetid;
int? ssoGroupId;
int? vptemplateID;
String? emailOrPhone;
int? mobileValidateType;
Map? forgetpasswordresponseresult;
String? mainbaseurl;
Map? otpverifyresponseresult;
// Unit IDs for configuration
int dubbingunitid = 52;
int lightman_unitid = 4;
int production_unitid = 20;
int tech_unitid = 29;
int juinor_unitid = 12;
int allowanceid_withoutbreak = 14;
int allowanceid_helper = 23;
int allowanceid_incharge = 24;

// API Endpoints
final processRequest = Uri.parse(
  'https://devvgate.vframework.in/vgateapi/processRequest',
);
final processSessionRequest = Uri.parse(
  'https://devvgate.vframework.in/vgateapi/processSessionRequest',
);

// VMETID tokens for different operations
String vmetid_fetch_config_unit_allowance =
    "QFjnHX2oXXReKA3tMjSN4dO8aT2LlE8O098UrCx6/szGQef/YKIzM2LehxeOBDZDNKZaeuOkTBKOfTIg03wvVPXUONEXWTvvKrQQ7heqxVKuyDxiMRcyPqLTkbcMAiibPoSJGSCUIhYToVwE+TWVLUW2Ke68yJdCgMrKFAxMwkx+yZdfZkSYILX25NMAunaH7ziKHEfbinOTQdIUR9xGnH9uord4oVLNW7vPSjVNkc7VAbpuz8L8Qr5I4FYUDKRDuz63H0XZSeX2+U6kzaSPMk870Y/jW+V47iYb2z4OQryivUdycPtdj6Zm7Wt8WWk8jGQJRFWx+UVUIs16c11Kqg==";

String vmetid_Fecth_callsheet_members =
    "VtHdAOR3ljcro4U+M9+kByyNPjr8d/b3VNhQmK9lwHYmkC5cUmqkmv6Ku5FFOHTYi9W80fZoAGhzNSB9L/7VCTAfg9S2RhDOMd5J+wkFquTCikvz38ZUWaUe6nXew/NSdV9K58wL5gDAd/7W0zSOpw7Qb+fALxSDZ8UmWdk7MxLkZDn0VIHwVAgv13JeeZVivtG7gu0DJvTyPixMJUFCQzzADzJHoIYtgXV4342izgfc4Lqca4rdjVwYV79/LLqmz1M8yAWXqfSRb+ArLo6xtPrjPInGZcIO8U6uTH1WmXvw+pk3xKD/WEEAFk69w8MI1TrntrzGgDPZ21NhqZXE/w==";

String vmetid_save_config =
    "gFKVWEa2ILpLKWOx4gmKQmg+XgFaJTS0LO8qTryiXNVFrOrWJfUJQcCY+ZYIVlIE+IQuidE5H/YF2ihIrxCPO5mztWxu31g51Hd2YN3rtX0t53OAMBuBgFx3PJ3zREuW/9cw6Tj9+wdLEeMUZpSfzpMv1I0YuzwLInyHSRypIkcQD1MoFA9jUNpg6I7Ezpy/w1fJcpE4/GlN7HJKjtkJ/Xsg1YCRtc4xz5jc/5zy7SJxSbCl/WLmQxP4Nz0hS5HqtbshLEnQjflTfnq3NakSJkhlDdY6J6AdP0SDZzYKSQVnViQ1w+Euc14vg3SP+7I3hkETu25vvGDieIqMI+XdMQ==";

String vmetid_fetch_unit =
    "Zfryf2Jt7ZnHxP57cfHT0n2vmTihWPqkwA8/pppCsOODTriG9m20x+DOfaKwZiJZTXYMUS2BVh/1fk0LWpYMjmey/SADWvv7XQ2Cmyxpsf0++IQjT4YhEnHGkgyuoc2pxZyaw2bDIhzje7JOFAGkVjIFCvvN3TsWXxqH5boL+bhlmIIlNGqGivm+gLqR9RnU4E6YZcC6eRF030s6pdTQagY17SU3O4TfUNgdAFEcsADAh3V8TfxDPMG8Ih1iGRPZnD25WlmJXXyeSVmFBoW+R2UDa3mHhdUGPNwFZIqAJbmbMvdOHriIfO2yElyDYUCBXNZmF4Z622R3xFeuPcDcpA==";

String vmetid_baseurl =
    'byrZ4bZrKm09R4O7WH6SPd7tvAtGnK1/plycMSP8sD5TKI/VZR0tHBKyO/ogYUIf4Qk6HJXvgyGzg58v0xmlMoRJABt3qUUWGtnJj/EKBsrOaFFGZ6xAbf6k6/ktf2gKsruyfbF2/D7r1CFZgUlmTmubGS1oMZZTSU433swBQbwLnPSreMNi8lIcHJKR2WepQnzNkwPPXxA4/XuZ7CZqqsfO6tmjnH47GoHr7H+FC8GK24zU3AwGIpX+Yg/efeibwapkP6mAya+5BTUGtNtltGOm0q7+2EJAfNcrSTdmoDB8xBerLaNNHhwVHowNIu+8JZl2QM0F/gmVpB55cB8rqg==';

String vmetid_login =
    'jcd3r0UZg4FnqnFKCfAZqwj+d5Y7TJhxN6vIvKsoJIT++90iKP3dELmti79Q+W7aVywvVbhfoF5bdW32p33PbRRTT27Jt3pahRrFzUe5s0jQBoeE0jOraLITDQ6RBv0QoscoOGxL7n0gEWtLE15Bl/HSF2kG5pQYft+ZyF4DNsLf7tGXTz+w/30bv6vMTGmwUIDWqbEet/+5AAjgxEMT/G4kiZifX0eEb3gMxycdMchucGbMkhzK+4bvZKmIjX+z6uz7xqb1SMgPnjKmoqCk8w833K9le4LQ3KSYkcVhyX9B0Q3dDc16JDtpEPTz6b8rTwY8puqlzfuceh5mWogYuA==';

String vmetid_checktheperson =
    'fG5k1mWf1OZYinDoY0evBxUZghzEKbrAYeHxQXR4rxFG2XqxVC1CgDUhyUMZM7V0ivoycMFgfIQOzKbug+G+bJVI3hz8Y45cPST676lSzGbR5LukGZECqIFu19CtIdhw/5obOGs1ZGE1MwKpebWTDhsfRL6adTdCUWB3YAQ8/a8pXYx8lACaEs9Ri2D2m7d+h+fOcdQQlpdlpdwxxLAVvnee8OYE39miaxpJFULkWCJhXomrQvOZjCGFzjAF9QWZuGshGb2Xl/gOutmzxplKIc8UBSwApq+6NLuaIsHc+MknqhonpGNq5JJQRRXKMXaVYbhdWDPXQZ8QqhfFrGpDTA==';
// Base URLs for different environments
String dancebaseurl = "dubbingmember.cinefo.club";
String dancebaseurlfordev = "dubbingmember.cinefo.club";
String dancebaseurlforproduction = "driversmember.cinefo.com";

String cinefoagent = 'assets/cine agent.png';
String cinefodriver = 'assets/driver_union_logo.png';
String cinefoproduction = 'assets/tenkrow.png';
String cinefologo = 'assets/cinefo-logo.png';
String cinefo__logo = 'assets/cinefomainlogo.jpeg';
String dance__logo = 'assets/Dancers.png';
String setting__logo = 'assets/Setting_Union_Logo.png';

// Global RouteObserver used by pages that implement RouteAware to refresh on navigation
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// Global key to show SnackBars from non-UI code (e.g. API helpers)
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Global key for navigation from non-UI code (e.g. API helpers for session expiration)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
