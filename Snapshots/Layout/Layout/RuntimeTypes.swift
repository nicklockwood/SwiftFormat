//  Copyright © 2017 Schibsted. All rights reserved.

import CoreGraphics
import Foundation
import QuartzCore
import UIKit
import WebKit

public extension RuntimeType {
    // MARK: Swift

    @objc static let any = RuntimeType(Any.self)
    @objc static let bool = RuntimeType(Bool.self)
    @objc static let double = RuntimeType(Double.self)
    @objc static let float = RuntimeType(Float.self)
    @objc static let int = RuntimeType(Int.self)
    @objc static let string = RuntimeType(String.self)
    @objc static let uInt = RuntimeType(UInt.self)

    // MARK: Foundation

    @objc static let anyObject = RuntimeType(AnyObject.self)
    @objc static let selector = RuntimeType(Selector.self)
    @objc static let nsAttributedString = RuntimeType(NSAttributedString.self)
    @objc static let url = RuntimeType(URL.self)
    @objc static let urlRequest = RuntimeType(URLRequest.self)

    // MARK: CoreGraphics

    @objc static let cgAffineTransform = RuntimeType(CGAffineTransform.self)
    @objc static let cgColor = RuntimeType(CGColor.self)
    @objc static let cgFloat = RuntimeType(CGFloat.self)
    @objc static let cgImage = RuntimeType(CGImage.self)
    @objc static let cgPath = RuntimeType(CGPath.self)
    @objc static let cgPoint = RuntimeType(CGPoint.self)
    @objc static let cgRect = RuntimeType(CGRect.self)
    @objc static let cgSize = RuntimeType(CGSize.self)
    @objc static let cgVector = RuntimeType(CGVector.self)

    // MARK: QuartzCore

    @objc static let caTransform3D = RuntimeType(CATransform3D.self)
    @objc static let caEdgeAntialiasingMask = RuntimeType([
        "layerLeftEdge": .layerLeftEdge,
        "layerRightEdge": .layerRightEdge,
        "layerBottomEdge": .layerBottomEdge,
        "layerTopEdge": .layerTopEdge,
    ] as [String: CAEdgeAntialiasingMask])

    @objc static let caCornerMask: RuntimeType = {
        if #available(iOS 11.0, *) {
            return RuntimeType([
                "layerMinXMinYCorner": .layerMinXMinYCorner,
                "layerMaxXMinYCorner": .layerMaxXMinYCorner,
                "layerMinXMaxYCorner": .layerMinXMaxYCorner,
                "layerMaxXMaxYCorner": .layerMaxXMaxYCorner,
            ] as [String: CACornerMask])
        }
        return RuntimeType([
            "layerMinXMinYCorner": UIntOptionSet(rawValue: 1),
            "layerMaxXMinYCorner": UIntOptionSet(rawValue: 2),
            "layerMinXMaxYCorner": UIntOptionSet(rawValue: 4),
            "layerMaxXMaxYCorner": UIntOptionSet(rawValue: 8),
        ] as [String: UIntOptionSet])
    }()

    @objc static let caLayerContentsGravity: RuntimeType = {
        #if swift(>=4.2)
            return RuntimeType([
                "center": .center,
                "top": .top,
                "bottom": .bottom,
                "left": .left,
                "right": .right,
                "topLeft": .topLeft,
                "topRight": .topRight,
                "bottomLeft": .bottomLeft,
                "bottomRight": .bottomRight,
                "resize": .resize,
                "resizeAspect": .resizeAspect,
                "resizeAspectFill": .resizeAspectFill,
            ] as [String: CALayerContentsGravity])
        #else
            return RuntimeType([
                "center",
                "top",
                "bottom",
                "left",
                "right",
                "topLeft",
                "topRight",
                "bottomLeft",
                "bottomRight",
                "resize",
                "resizeAspect",
                "resizeAspectFill",
            ] as Set<String>)
        #endif
    }()

    @objc static let caMediaTimingFillMode: RuntimeType = {
        #if swift(>=4.2)
            return RuntimeType([
                "backwards": .backwards,
                "forwards": .forwards,
                "both": .both,
                "removed": .removed,
            ] as [String: CAMediaTimingFillMode])
        #else
            return RuntimeType([
                "backwards",
                "forwards",
                "both",
                "removed",
            ] as Set<String>)
        #endif
    }()

    @objc static let caLayerContentsFilter: RuntimeType = {
        #if swift(>=4.2)
            return RuntimeType([
                "nearest": .nearest,
                "linear": .linear,
            ] as [String: CALayerContentsFilter])
        #else
            return RuntimeType([
                "nearest",
                "linear",
            ] as Set<String>)
        #endif
    }()

    // MARK: UIKit

    @objc static let uiColor = RuntimeType(UIColor.self)
    @objc static let uiImage = RuntimeType(UIImage.self)
    @objc static let uiActivity_ActivityType: RuntimeType = {
        var values: [String: UIActivity.ActivityType] = [
            "postToFacebook": .postToFacebook,
            "postToTwitter": .postToTwitter,
            "postToWeibo": .postToWeibo,
            "message": .message,
            "mail": .mail,
            "print": .print,
            "copyToPasteboard": .copyToPasteboard,
            "assignToContact": .assignToContact,
            "saveToCameraRoll": .saveToCameraRoll,
            "addToReadingList": .addToReadingList,
            "postToFlickr": .postToFlickr,
            "postToVimeo": .postToVimeo,
            "postToTencentWeibo": .postToTencentWeibo,
            "airDrop": .airDrop,
            "openInIBooks": .openInIBooks,
        ]
        if #available(iOS 11.0, *) {
            values["markupAsPDF"] = .markupAsPDF
        }
        return RuntimeType(values)
    }()

    // Deprecated

    @objc static var uiActivityType: RuntimeType { return uiActivity_ActivityType }

    // MARK: Accessibility

    @objc static let uiAccessibilityContainerType: RuntimeType = {
        if #available(iOS 11.0, *) {
            return RuntimeType([
                "none": .none,
                "dataTable": .dataTable,
                "list": .list,
                "landmark": .landmark,
            ] as [String: UIAccessibilityContainerType])
        }
        return RuntimeType([
            "none": 0,
            "dataTable": 1,
            "list": 2,
            "landmark": 3,
        ] as [String: Int])
    }()

    @objc static let uiAccessibilityNavigationStyle = RuntimeType([
        "automatic": .automatic,
        "separate": .separate,
        "combined": .combined,
    ] as [String: UIAccessibilityNavigationStyle])
    @objc static let uiAccessibilityTraits: RuntimeType = {
        let tabBarTrait: UIAccessibilityTraits
        if #available(iOS 10, *) {
            tabBarTrait = UIAccessibilityTraits.tabBar
        } else {
            tabBarTrait = UIAccessibilityTraits.none
        }
        let type = RuntimeType(RuntimeType.Kind.options(UIAccessibilityTraits.self, [
            "none": UIAccessibilityTraits.none,
            "button": UIAccessibilityTraits.button,
            "link": UIAccessibilityTraits.link,
            "header": UIAccessibilityTraits.header,
            "searchField": UIAccessibilityTraits.searchField,
            "image": UIAccessibilityTraits.image,
            "selected": UIAccessibilityTraits.selected,
            "playsSound": UIAccessibilityTraits.playsSound,
            "keyboardKey": UIAccessibilityTraits.keyboardKey,
            "staticText": UIAccessibilityTraits.staticText,
            "summaryElement": UIAccessibilityTraits.summaryElement,
            "notEnabled": UIAccessibilityTraits.notEnabled,
            "updatesFrequently": UIAccessibilityTraits.updatesFrequently,
            "startsMediaSession": UIAccessibilityTraits.startsMediaSession,
            "adjustable": UIAccessibilityTraits.adjustable,
            "allowsIndirectInteraction": UIAccessibilityTraits.allowsDirectInteraction,
            "causesPageTurn": UIAccessibilityTraits.causesPageTurn,
            "tabBar": tabBarTrait,
        ] as [String: UIAccessibilityTraits]))
        type.caster = { value in
            if let values = value as? [UIAccessibilityTraits] {
                #if swift(>=4.2)
                    return UIAccessibilityTraits(rawValue: values.map { $0.rawValue }.reduce(0 as UInt64) { $0 + $1 })
                #else
                    return values.reduce(0) { $0 + $1 }
                #endif
            }
            return value as? UIAccessibilityTraits
        }
        return type
    }()

    // MARK: Geometry

    @objc static let uiBezierPath = RuntimeType(UIBezierPath.self)
    @objc static let uiEdgeInsets = RuntimeType(UIEdgeInsets.self)
    @objc static let uiOffset = RuntimeType(UIOffset.self)
    @objc static let uiRectEdge = RuntimeType([
        "top": .top,
        "left": .left,
        "bottom": .bottom,
        "right": .right,
        "all": .all,
    ] as [String: UIRectEdge])

    // MARK: Text

    @objc static let nsLineBreakMode = RuntimeType([
        "byWordWrapping": .byWordWrapping,
        "byCharWrapping": .byCharWrapping,
        "byClipping": .byClipping,
        "byTruncatingHead": .byTruncatingHead,
        "byTruncatingTail": .byTruncatingTail,
        "byTruncatingMiddle": .byTruncatingMiddle,
    ] as [String: NSLineBreakMode])
    @objc static let nsTextAlignment = RuntimeType([
        "left": .left,
        "right": .right,
        "center": .center,
        "justified": .justified,
        "natural": .natural,
    ] as [String: NSTextAlignment])
    @objc static let uiBaselineAdjustment = RuntimeType([
        "alignBaselines": .alignBaselines,
        "alignCenters": .alignCenters,
        "none": .none,
    ] as [String: UIBaselineAdjustment])
    @objc static let uiDataDetectorTypes: RuntimeType = {
        let types = [
            "phoneNumber": .phoneNumber,
            "link": .link,
            "address": .address,
            "calendarEvent": .calendarEvent,
            "shipmentTrackingNumber": [],
            "flightNumber": [],
            "lookupSuggestion": [],
            "all": .all,
        ] as [String: UIDataDetectorTypes]
        if #available(iOS 11.0, *) {
            var types = types
            types["shipmentTrackingNumber"] = .shipmentTrackingNumber
            types["flightNumber"] = .flightNumber
            types["lookupSuggestion"] = .lookupSuggestion
            return RuntimeType(types)
        }
        return RuntimeType(types)
    }()

    @objc static let uiFont = RuntimeType(UIFont.self)
    @objc static let uiFontDescriptor_SymbolicTraits = RuntimeType([
        "traitItalic": .traitItalic,
        "traitBold": .traitBold,
        "traitExpanded": .traitExpanded,
        "traitCondensed": .traitCondensed,
        "traitMonoSpace": .traitMonoSpace,
        "traitVertical": .traitVertical,
        "traitUIOptimized": .traitUIOptimized,
        "traitTightLeading": .traitTightLeading,
        "traitLooseLeading": .traitLooseLeading,
    ] as [String: UIFontDescriptor.SymbolicTraits])
    @objc static let uiFont_TextStyle = RuntimeType([
        "title1": .title1,
        "title2": .title2,
        "title3": .title3,
        "headline": .headline,
        "subheadline": .subheadline,
        "body": .body,
        "callout": .callout,
        "footnote": .footnote,
        "caption1": .caption1,
        "caption2": .caption2,
    ] as [String: UIFont.TextStyle])
    @objc static let uiFont_Weight = RuntimeType([
        "ultraLight": .ultraLight,
        "thin": .thin,
        "light": .light,
        "regular": .regular,
        "medium": .medium,
        "semibold": .semibold,
        "bold": .bold,
        "heavy": .heavy,
        "black": .black,
    ] as [String: UIFont.Weight])

    // Deprecated

    @objc static var uiFontDescriptorSymbolicTraits: RuntimeType { return uiFontDescriptor_SymbolicTraits }
    @objc static var uiFontTextStyle: RuntimeType { return uiFont_TextStyle }

    // MARK: TextInput

    @objc static let uiKeyboardAppearance = RuntimeType([
        "default": .default,
        "dark": .dark,
        "light": .light,
    ] as [String: UIKeyboardAppearance])
    @objc static let uiKeyboardType: RuntimeType = {
        var keyboardTypes: [String: UIKeyboardType] = [
            "default": .default,
            "asciiCapable": .asciiCapable,
            "asciiCapableNumberPad": .asciiCapable,
            "numbersAndPunctuation": .numbersAndPunctuation,
            "URL": .URL,
            "url": .URL,
            "numberPad": .numberPad,
            "phonePad": .phonePad,
            "namePhonePad": .namePhonePad,
            "emailAddress": .emailAddress,
            "decimalPad": .decimalPad,
            "twitter": .twitter,
            "webSearch": .webSearch,
        ]
        if #available(iOS 10.0, *) {
            keyboardTypes["asciiCapableNumberPad"] = .asciiCapableNumberPad
        }
        return RuntimeType(keyboardTypes)
    }()

    @objc static let uiReturnKeyType = RuntimeType([
        "default": .default,
        "go": .go,
        "google": .google,
        "join": .join,
        "next": .next,
        "route": .route,
        "search": .search,
        "send": .send,
        "yahoo": .yahoo,
        "done": .done,
        "emergencyCall": .emergencyCall,
        "continue": .continue,
    ] as [String: UIReturnKeyType])
    @objc static let uiTextAutocapitalizationType = RuntimeType([
        "none": .none,
        "words": .words,
        "sentences": .sentences,
        "allCharacters": .allCharacters,
    ] as [String: UITextAutocapitalizationType])
    @objc static let uiTextAutocorrectionType = RuntimeType([
        "default": .default,
        "no": .no,
        "yes": .yes,
    ] as [String: UITextAutocorrectionType])
    @objc static let uiTextContentType: RuntimeType = {
        if #available(iOS 10.0, *) {
            var contentTypes = [
                "name": .name,
                "namePrefix": .namePrefix,
                "givenName": .givenName,
                "middleName": .middleName,
                "familyName": .familyName,
                "nameSuffix": .nameSuffix,
                "nickname": .nickname,
                "jobTitle": .jobTitle,
                "organizationName": .organizationName,
                "location": .location,
                "fullStreetAddress": .fullStreetAddress,
                "streetAddressLine1": .streetAddressLine1,
                "streetAddressLine2": .streetAddressLine2,
                "addressCity": .addressCity,
                "addressState": .addressState,
                "addressCityAndState": .addressCityAndState,
                "sublocality": .sublocality,
                "countryName": .countryName,
                "postalCode": .postalCode,
                "telephoneNumber": .telephoneNumber,
                "emailAddress": .emailAddress,
                "URL": .URL,
                "creditCardNumber": .creditCardNumber,
                // Compatibility
                "username": .name,
                "password": .name,
                "newPassword": .name,
                "oneTimeCode": .name,
            ] as [String: UITextContentType]
            if #available(iOS 11.0, *) {
                contentTypes["username"] = .username
                contentTypes["password"] = .password
            }
            #if swift(>=4.1.5) || (!swift(>=4) && swift(>=3.4))
                if #available(iOS 12.0, *) {
                    contentTypes["newPassword"] = .newPassword
                    contentTypes["oneTimeCode"] = .oneTimeCode
                }
            #endif
            return RuntimeType(contentTypes)
        }
        return RuntimeType(Set([
            "name",
            "namePrefix",
            "givenName",
            "middleName",
            "familyName",
            "nameSuffix",
            "nickname",
            "jobTitle",
            "organizationName",
            "location",
            "fullStreetAddress",
            "streetAddressLine1",
            "streetAddressLine2",
            "addressCity",
            "addressState",
            "addressCityAndState",
            "sublocality",
            "countryName",
            "postalCode",
            "telephoneNumber",
            "emailAddress",
            "URL",
            "creditCardNumber",
            "username",
            "password",
            "newPassword",
            "oneTimeCode",
        ]))
    }()

    @objc static let uiTextInputPasswordRules: RuntimeType = {
        #if swift(>=4.1.5) || (!swift(>=4) && swift(>=3.4))
            if #available(iOS 12.0, *) {
                // TODO: allow configuration with descriptor String?
                return RuntimeType(UITextInputPasswordRules.self)
            }
        #endif
        return .any
    }()

    @objc static let uiTextSmartQuotesType: RuntimeType = {
        if #available(iOS 11.0, *) {
            return RuntimeType([
                "default": .default,
                "no": .no,
                "yes": .yes,
            ] as [String: UITextSmartQuotesType])
        }
        return RuntimeType([
            "default": 0,
            "no": 1,
            "yes": 2,
        ] as [String: Int])
    }()

    @objc static let uiTextSmartDashesType: RuntimeType = {
        if #available(iOS 11.0, *) {
            return RuntimeType([
                "default": .default,
                "no": .no,
                "yes": .yes,
            ] as [String: UITextSmartDashesType])
        }
        return RuntimeType([
            "default": 0,
            "no": 1,
            "yes": 2,
        ] as [String: Int])
    }()

    @objc static let uiTextSmartInsertDeleteType: RuntimeType = {
        if #available(iOS 11.0, *) {
            return RuntimeType([
                "default": .default,
                "no": .no,
                "yes": .yes,
            ] as [String: UITextSmartInsertDeleteType])
        }
        return RuntimeType([
            "default": 0,
            "no": 1,
            "yes": 2,
        ] as [String: Int])
    }()

    @objc static let uiTextSpellCheckingType = RuntimeType([
        "default": .default,
        "no": .no,
        "yes": .yes,
    ] as [String: UITextSpellCheckingType])

    // MARK: UITextField

    @objc static let uiTextField_BorderStyle = RuntimeType([
        "none": .none,
        "line": .line,
        "bezel": .bezel,
        "roundedRect": .roundedRect,
    ] as [String: UITextField.BorderStyle])
    @objc static let uiTextField_ViewMode = RuntimeType([
        "never": .never,
        "whileEditing": .whileEditing,
        "unlessEditing": .unlessEditing,
        "always": .always,
    ] as [String: UITextField.ViewMode])

    // Deprecated

    @objc static var uiTextBorderStyle: RuntimeType { return uiTextField_BorderStyle }
    @objc static var uiTextFieldViewMode: RuntimeType { return uiTextField_ViewMode }

    // MARK: UISegmentedControl

    @objc static let uiSegmentedControl_Segment = RuntimeType([
        "any": .any,
        "left": .left,
        "center": .center,
        "right": .right,
        "alone": .alone,
    ] as [String: UISegmentedControl.Segment])

    // Deprecated

    @objc static var uiSegmentedControlSegment: RuntimeType { return uiSegmentedControl_Segment }

    // MARK: Toolbars

    @objc static let uiBarStyle = RuntimeType([
        "default": .default,
        "black": .black,
    ] as [String: UIBarStyle])
    @objc static let uiBarPosition = RuntimeType([
        "any": .any,
        "bottom": .bottom,
        "top": .top,
        "topAttached": .topAttached,
    ] as [String: UIBarPosition])
    @objc static let uiSearchBar_Style = RuntimeType([
        "default": .default,
        "prominent": .prominent,
        "minimal": .minimal,
    ] as [String: UISearchBar.Style])
    @objc static let uiBarButtonItem_SystemItem = RuntimeType([
        "done": .done,
        "cancel": .cancel,
        "edit": .edit,
        "save": .add,
        "flexibleSpace": .flexibleSpace,
        "fixedSpace": .fixedSpace,
        "compose": .compose,
        "reply": .reply,
        "action": .action,
        "organize": .organize,
        "bookmarks": .bookmarks,
        "search": .search,
        "refresh": .refresh,
        "stop": .stop,
        "camera": .camera,
        "trash": .trash,
        "play": .play,
        "pause": .pause,
        "rewind": .rewind,
        "fastForward": .fastForward,
        "undo": .undo,
        "redo": .redo,
        "pageCurl": .pageCurl,
    ] as [String: UIBarButtonItem.SystemItem])
    @objc static let uiBarButtonItem_Style = RuntimeType([
        "plain": .plain,
        "done": .done,
    ] as [String: UIBarButtonItem.Style])
    @objc static let uiTabBarItem_SystemItem = RuntimeType([
        "more": .more,
        "favorites": .favorites,
        "featured": .featured,
        "topRated": .topRated,
        "recents": .recents,
        "contacts": .contacts,
        "history": .history,
        "bookmarks": .bookmarks,
        "search": .search,
        "downloads": .downloads,
        "mostRecent": .mostRecent,
        "mostViewed": .mostViewed,
    ] as [String: UITabBarItem.SystemItem])

    // Deprecated

    @objc static var uiSearchBarStyle: RuntimeType { return uiSearchBar_Style }
    @objc static var uiBarButtonSystemItem: RuntimeType { return uiBarButtonItem_SystemItem }
    @objc static var uiBarButtonItemStyle: RuntimeType { return uiBarButtonItem_Style }
    @objc static var uiTabBarSystemItem: RuntimeType { return uiTabBarItem_SystemItem }

    // MARK: Drag and drop

    @objc static let uiTextDragDelegate: RuntimeType = {
        if #available(iOS 11.0, *) {
            return RuntimeType(UITextDragDelegate.self)
        }
        return .anyObject
    }()

    @objc static let uiTextDropDelegate: RuntimeType = {
        if #available(iOS 11.0, *) {
            return RuntimeType(UITextDropDelegate.self)
        }
        return .anyObject
    }()

    @objc static let uiTextDragOptions: RuntimeType = {
        if #available(iOS 11.0, *) {
            return RuntimeType([
                "stripTextColorFromPreviews": .stripTextColorFromPreviews,
            ] as [String: UITextDragOptions])
        }
        return RuntimeType([
            "stripTextColorFromPreviews": IntOptionSet(rawValue: 1),
        ] as [String: IntOptionSet])
    }()

    // MARK: UIView

    @objc static let uiView_AutoresizingMask = RuntimeType([
        "flexibleLeftMargin": .flexibleLeftMargin,
        "flexibleWidth": .flexibleWidth,
        "flexibleRightMargin": .flexibleRightMargin,
        "flexibleTopMargin": .flexibleTopMargin,
        "flexibleHeight": .flexibleHeight,
        "flexibleBottomMargin": .flexibleBottomMargin,
    ] as [String: UIView.AutoresizingMask])
    @objc static let uiSemanticContentAttribute = RuntimeType([
        "unspecified": .unspecified,
        "playback": .playback,
        "spatial": .spatial,
        "forceLeftToRight": .forceLeftToRight,
        "forceRightToLeft": .forceRightToLeft,
    ] as [String: UISemanticContentAttribute])
    @objc static let uiView_ContentMode = RuntimeType([
        "scaleToFill": .scaleToFill,
        "scaleAspectFit": .scaleAspectFit,
        "scaleAspectFill": .scaleAspectFill,
        "redraw": .redraw,
        "center": .center,
        "top": .top,
        "bottom": .bottom,
        "left": .left,
        "right": .right,
        "topLeft": .topLeft,
        "topRight": .topRight,
        "bottomLeft": .bottomLeft,
        "bottomRight": .bottomRight,
    ] as [String: UIView.ContentMode])
    @objc static let uiView_TintAdjustmentMode = RuntimeType([
        "automatic": .automatic,
        "normal": .normal,
        "dimmed": .dimmed,
    ] as [String: UIView.TintAdjustmentMode])

    // Deprecated

    @objc static var uiViewAutoresizing: RuntimeType { return uiView_AutoresizingMask }
    @objc static var uiViewContentMode: RuntimeType { return uiView_ContentMode }
    @objc static var uiViewTintAdjustmentMode: RuntimeType { return uiView_TintAdjustmentMode }

    // MARK: UIControl

    @objc static let uiControl_ContentVerticalAlignment = RuntimeType([
        "center": .center,
        "top": .top,
        "bottom": .bottom,
        "fill": .fill,
    ] as [String: UIControl.ContentVerticalAlignment])
    @objc static let uiControl_ContentHorizontalAlignment = RuntimeType([
        "center": .center,
        "left": .left,
        "right": .right,
        "fill": .fill,
    ] as [String: UIControl.ContentHorizontalAlignment])

    // Deprecated

    @objc static var uiControlContentVerticalAlignment: RuntimeType { return uiControl_ContentVerticalAlignment }
    @objc static var uiControlContentHorizontalAlignment: RuntimeType { return uiControl_ContentHorizontalAlignment }

    // MARK: UIButton

    @objc static let uiButton_ButtonType = RuntimeType([
        "custom": .custom,
        "system": .system,
        "detailDisclosure": .detailDisclosure,
        "infoLight": .infoLight,
        "infoDark": .infoDark,
        "contactAdd": .contactAdd,
    ] as [String: UIButton.ButtonType])

    // Deprecated

    @objc static var uiButtonType: RuntimeType { return uiButton_ButtonType }

    // MARK: UIActivityIndicatorView

    @objc static let uiActivityIndicatorView_Style = RuntimeType([
        "whiteLarge": .whiteLarge,
        "white": .white,
        "gray": .gray,
    ] as [String: UIActivityIndicatorView.Style])

    // Deprecated

    @objc static var uiActivityIndicatorViewStyle: RuntimeType { return uiActivityIndicatorView_Style }

    // MARK: UIProgressView

    @objc static let uiProgressView_Style = RuntimeType([
        "default": .default,
        "bar": .bar,
    ] as [String: UIProgressView.Style])

    // Deprecated

    @objc static var uiProgressViewStyle: RuntimeType { return uiProgressView_Style }

    // MARK: UIInputView

    @objc static let uiInputView_Style = RuntimeType([
        "default": .default,
        "keyboard": .keyboard,
    ] as [String: UIInputView.Style])

    // Deprecated

    @objc static var uiInputViewStyle: RuntimeType { return uiInputView_Style }

    // MARK: UIDatePicker

    @objc static let uiDatePicker_Mode = RuntimeType([
        "time": .time,
        "date": .date,
        "dateAndTime": .dateAndTime,
        "countDownTimer": .countDownTimer,
    ] as [String: UIDatePicker.Mode])

    // Deprecated

    @objc static var uiDatePickerMode: RuntimeType { return uiDatePicker_Mode }

    // MARK: UIScrollView

    @objc static let uiScrollView_ContentInsetAdjustmentBehavior: RuntimeType = {
        if #available(iOS 11.0, *) {
            #if swift(>=4.2)
                typealias ContentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior
            #else
                typealias ContentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior
            #endif
            return RuntimeType([
                "automatic": .automatic,
                "scrollableAxes": .scrollableAxes,
                "never": .never,
                "always": .always,
            ] as [String: ContentInsetAdjustmentBehavior])
        }
        return RuntimeType([
            "automatic": 0,
            "scrollableAxes": 1,
            "never": 2,
            "always": 3,
        ] as [String: Int])
    }()

    @objc static let uiScrollView_DecelerationRate = RuntimeType([
        "normal": .normal,
        "fast": .fast,
    ] as [String: UIScrollView.DecelerationRate])
    @objc static let uiScrollView_IndicatorStyle = RuntimeType([
        "default": .default,
        "black": .black,
        "white": .white,
    ] as [String: UIScrollView.IndicatorStyle])
    @objc static let uiScrollView_IndexDisplayMode = RuntimeType([
        "automatic": .automatic,
        "alwaysHidden": .alwaysHidden,
    ] as [String: UIScrollView.IndexDisplayMode])
    @objc static let uiScrollView_KeyboardDismissMode = RuntimeType([
        "none": .none,
        "onDrag": .onDrag,
        "interactive": .interactive,
    ] as [String: UIScrollView.KeyboardDismissMode])

    // Deprecated

    @objc static var uiScrollViewContentInsetAdjustmentBehavior: RuntimeType { return uiScrollView_ContentInsetAdjustmentBehavior }
    @objc static var uiScrollViewIndicatorStyle: RuntimeType { return uiScrollView_IndicatorStyle }
    @objc static var uiScrollViewIndexDisplayMode: RuntimeType { return uiScrollView_IndexDisplayMode }
    @objc static var uiScrollViewKeyboardDismissMode: RuntimeType { return uiScrollView_KeyboardDismissMode }

    // MARK: UICollectionView

    @objc static let uiCollectionView_ScrollDirection = RuntimeType([
        "horizontal": .horizontal,
        "vertical": .vertical,
    ] as [String: UICollectionView.ScrollDirection])
    @objc static let uiCollectionView_ReorderingCadence: RuntimeType = {
        if #available(iOS 11.0, *) {
            #if swift(>=4.2)
                typealias ReorderingCadence = UICollectionView.ReorderingCadence
            #else
                typealias ReorderingCadence = UICollectionViewReorderingCadence
            #endif
            return RuntimeType([
                "immediate": .immediate,
                "fast": .fast,
                "slow": .slow,
            ] as [String: ReorderingCadence])
        }
        return RuntimeType([
            "immediate": 0,
            "fast": 1,
            "slow": 2,
        ] as [String: Int])
    }()

    @objc static let uiCollectionViewFlowLayout_SectionInsetReference: RuntimeType = {
        if #available(iOS 11.0, *) {
            #if swift(>=4.2)
                typealias SectionInsetReference = UICollectionViewFlowLayout.SectionInsetReference
            #else
                typealias SectionInsetReference = UICollectionViewFlowLayoutSectionInsetReference
            #endif
            return RuntimeType([
                "fromContentInset": .fromContentInset,
                "fromSafeArea": .fromSafeArea,
                "fromLayoutMargins": .fromLayoutMargins,
            ] as [String: SectionInsetReference])
        }
        return RuntimeType([
            "fromContentInset": 0,
            "fromSafeArea": 1,
            "fromLayoutMargins": 2,
        ] as [String: Int])
    }()

    // Deprecated

    @objc static var uiCollectionViewScrollDirection: RuntimeType { return uiCollectionView_ScrollDirection }
    @objc static var uiCollectionViewReorderingCadence: RuntimeType { return uiCollectionView_ReorderingCadence }
    @objc static var uiCollectionViewFlowLayoutSectionInsetReference: RuntimeType { return uiCollectionViewFlowLayout_SectionInsetReference }

    // MARK: UIStackView

    @objc static let nsLayoutConstraint_Axis = RuntimeType([
        "horizontal": .horizontal,
        "vertical": .vertical,
    ] as [String: NSLayoutConstraint.Axis])
    @objc static let uiLayoutPriority = RuntimeType(
        RuntimeType.Kind.options(UILayoutPriority.self, [
            "required": .required,
            "defaultHigh": .defaultHigh,
            "defaultLow": .defaultLow,
            "fittingSizeLevel": .fittingSizeLevel,
        ] as [String: UILayoutPriority])
    )
    @objc static let uiStackView_Distribution = RuntimeType([
        "fill": .fill,
        "fillEqually": .fillEqually,
        "fillProportionally": .fillProportionally,
        "equalSpacing": .equalSpacing,
        "equalCentering": .equalCentering,
    ] as [String: UIStackView.Distribution])
    @objc static let uiStackView_Alignment = RuntimeType([
        "fill": .fill,
        "leading": .leading,
        "top": .top,
        "firstBaseline": .firstBaseline,
        "center": .center,
        "trailing": .trailing,
        "bottom": .bottom,
        "lastBaseline": .lastBaseline, // Valid for horizontal axis only
    ] as [String: UIStackView.Alignment])

    // Deprecated

    @objc static var uiLayoutConstraintAxis: RuntimeType { return nsLayoutConstraint_Axis }
    @objc static var uiStackViewDistribution: RuntimeType { return uiStackView_Distribution }
    @objc static var uiStackViewAlignment: RuntimeType { return uiStackView_Alignment }

    // MARK: UITableViewCell

    @objc static let uiTableViewCell_AccessoryType = RuntimeType([
        "none": .none,
        "disclosureIndicator": .disclosureIndicator,
        "detailDisclosureButton": .detailDisclosureButton,
        "checkmark": .checkmark,
        "detailButton": .detailButton,
    ] as [String: UITableViewCell.AccessoryType])
    @objc static let uiTableViewCell_CellStyle = RuntimeType([
        "default": .default,
        "value1": .value1,
        "value2": .value2,
        "subtitle": .subtitle,
    ] as [String: UITableViewCell.CellStyle])
    @objc static let uiTableViewCell_FocusStyle = RuntimeType([
        "default": .default,
        "custom": .custom,
    ] as [String: UITableViewCell.FocusStyle])
    @objc static let uiTableViewCell_SelectionStyle = RuntimeType([
        "none": .none,
        "blue": .blue,
        "gray": .gray,
        "default": .default,
    ] as [String: UITableViewCell.SelectionStyle])
    @objc static let uiTableViewCell_SeparatorStyle = RuntimeType([
        "none": .none,
        "singleLine": .singleLine,
        "singleLineEtched": .singleLineEtched,
    ] as [String: UITableViewCell.SeparatorStyle])

    // Deprecated

    @objc static var uiTableViewCellAccessoryType: RuntimeType { return uiTableViewCell_AccessoryType }
    @objc static var uiTableViewCellFocusStyle: RuntimeType { return uiTableViewCell_FocusStyle }
    @objc static var uiTableViewCellSelectionStyle: RuntimeType { return uiTableViewCell_SelectionStyle }
    @objc static var uiTableViewCellSeparatorStyle: RuntimeType { return uiTableViewCell_SeparatorStyle }
    @objc static var uiTableViewCellStyle: RuntimeType { return uiTableViewCell_CellStyle }

    // MARK: UITableView

    @objc static let uiTableView_Style = RuntimeType([
        "plain": .plain,
        "grouped": .grouped,
    ] as [String: UITableView.Style])
    @objc static let uiTableView_SeparatorInsetReference: RuntimeType = {
        if #available(iOS 11.0, *) {
            #if swift(>=4.2)
                typealias SeparatorInsetReference = UITableView.SeparatorInsetReference
            #else
                typealias SeparatorInsetReference = UITableViewSeparatorInsetReference
            #endif
            return RuntimeType([
                "fromCellEdges": .fromCellEdges,
                "fromAutomaticInsets": .fromAutomaticInsets,
            ] as [String: SeparatorInsetReference])
        }
        return RuntimeType([
            "fromCellEdges": 0,
            "fromAutomaticInsets": 1,
        ] as [String: Int])
    }()

    // Deprecated

    @objc static var uiTableViewStyle: RuntimeType { return uiTableView_Style }
    @objc static var uiTableViewSeparatorInsetReference: RuntimeType { return uiTableView_SeparatorInsetReference }

    // MARK: UIWebView

    @objc static let uiWebView_PaginationMode = RuntimeType([
        "unpaginated": .unpaginated,
        "leftToRight": .leftToRight,
        "topToBottom": .topToBottom,
        "bottomToTop": .bottomToTop,
        "rightToLeft": .rightToLeft,
    ] as [String: UIWebView.PaginationMode])
    @objc static let uiWebView_PaginationBreakingMode = RuntimeType([
        "page": .page,
        "column": .column,
    ] as [String: UIWebView.PaginationBreakingMode])

    // Deprecated

    @objc static var uiWebPaginationMode: RuntimeType { return uiWebView_PaginationMode }
    @objc static var uiWebPaginationBreakingMode: RuntimeType { return uiWebView_PaginationBreakingMode }

    // MARK: WebKit

    @objc static let wkAudiovisualMediaTypes: RuntimeType = {
        if #available(iOS 10, *) {
            return RuntimeType([
                "audio": .audio,
                "video": .video,
                "all": .all,
            ] as [String: WKAudiovisualMediaTypes])
        }
        return RuntimeType([
            "audio": IntOptionSet(rawValue: 1),
            "video": IntOptionSet(rawValue: 2),
            "all": IntOptionSet(rawValue: 3),
        ] as [String: IntOptionSet])
    }()

    @objc static let wkDataDetectorTypes: RuntimeType = {
        if #available(iOS 10, *) {
            return RuntimeType([
                "phoneNumber": .phoneNumber,
                "link": .link,
                "address": .address,
                "calendarEvent": .calendarEvent,
                "trackingNumber": .trackingNumber,
                "flightNumber": .flightNumber,
                "lookupSuggestion": .lookupSuggestion,
                "all": .all,
            ] as [String: WKDataDetectorTypes])
        }
        return RuntimeType([
            "phoneNumber": IntOptionSet(rawValue: 1),
            "link": IntOptionSet(rawValue: 2),
            "address": IntOptionSet(rawValue: 4),
            "calendarEvent": IntOptionSet(rawValue: 8),
            "trackingNumber": IntOptionSet(rawValue: 16),
            "flightNumber": IntOptionSet(rawValue: 32),
            "lookupSuggestion": IntOptionSet(rawValue: 64),
            "all": IntOptionSet(rawValue: 127),
        ] as [String: IntOptionSet])
    }()

    @objc static let wkSelectionGranularity = RuntimeType([
        "dynamic": .dynamic,
        "character": .character,
    ] as [String: WKSelectionGranularity])

    // MARK: UIViewController

    @objc static let uiModalPresentationStyle = RuntimeType([
        "fullScreen": .fullScreen,
        "pageSheet": .pageSheet,
        "formSheet": .formSheet,
        "currentContext": .currentContext,
        "custom": .custom,
        "overFullScreen": .overFullScreen,
        "overCurrentContext": .overCurrentContext,
        "popover": .popover,
        "none": .none,
    ] as [String: UIModalPresentationStyle])
    @objc static let uiModalTransitionStyle = RuntimeType([
        "coverVertical": .coverVertical,
        "flipHorizontal": .flipHorizontal,
        "crossDissolve": .crossDissolve,
        "partialCurl": .partialCurl,
    ] as [String: UIModalTransitionStyle])
    @objc static let uiNavigationItem_LargeTitleDisplayMode = RuntimeType([
        "automatic": .automatic,
        "always": .always,
        "never": .never,
    ] as [String: UINavigationItem.LargeTitleDisplayMode])

    // MARK: UIAlertController

    @objc static let uiAlertController_Style = RuntimeType([
        "actionSheet": .actionSheet,
        "alert": .alert,
    ] as [String: UIAlertController.Style])

    // Deprecated

    @objc static var uiAlertControllerStyle: RuntimeType { return uiAlertController_Style }

    // MARK: UICloudSharingViewController

    @objc static let uiCloudSharingController_PermissionOptions: RuntimeType = {
        if #available(iOS 10.0, *) {
            #if swift(>=4.2)
                typealias PermissionOptions = UICloudSharingController.PermissionOptions
            #else
                typealias PermissionOptions = UICloudSharingPermissionOptions
            #endif
            return RuntimeType([
                "allowPublic": .allowPublic,
                "allowPrivate": .allowPrivate,
                "allowReadOnly": .allowReadOnly,
                "allowReadWrite": .allowReadWrite,
            ] as [String: PermissionOptions])
        }
        return RuntimeType([
            "allowPublic": 0,
            "allowPrivate": 1,
            "allowReadOnly": 2,
            "allowReadWrite": 3,
        ] as [String: Int])
    }()

    // Deprecated

    @objc static var uiCloudSharingPermissionOptions: RuntimeType { return uiCloudSharingController_PermissionOptions }

    // MARK: UIImagePickerController

    @objc static let uiImagePickerController_CameraCaptureMode = RuntimeType([
        "photo": .photo,
        "video": .video,
    ] as [String: UIImagePickerController.CameraCaptureMode])
    @objc static let uiImagePickerController_CameraDevice = RuntimeType([
        "rear": .rear,
        "front": .front,
    ] as [String: UIImagePickerController.CameraDevice])
    @objc static let uiImagePickerController_CameraFlashMode = RuntimeType([
        "off": .off,
        "auto": .auto,
        "on": .on,
    ] as [String: UIImagePickerController.CameraFlashMode])
    @objc static let uiImagePickerController_ImageURLExportPreset: RuntimeType = {
        if #available(iOS 11.0, *) {
            #if swift(>=4.2)
                typealias ImageURLExportPreset = UIImagePickerController.ImageURLExportPreset
            #else
                typealias ImageURLExportPreset = UIImagePickerControllerImageURLExportPreset
            #endif
            return RuntimeType([
                "compatible": .compatible,
                "current": .current,
            ] as [String: ImageURLExportPreset])
        }
        return RuntimeType([
            "compatible": IntOptionSet(rawValue: 1),
            "current": IntOptionSet(rawValue: 2),
        ] as [String: IntOptionSet])
    }()

    @objc static let uiImagePickerController_SourceType = RuntimeType([
        "photoLibrary": .photoLibrary,
        "camera": .camera,
        "savedPhotosAlbum": .savedPhotosAlbum,
    ] as [String: UIImagePickerController.SourceType])
    @objc static let uiImagePickerController_QualityType = RuntimeType([
        "typeHigh": .typeHigh,
        "typeMedium": .typeMedium,
        "typeLow": .typeLow,
        "type640x480": .type640x480,
        "typeIFrame1280x720": .typeIFrame1280x720,
        "typeIFrame960x540": .typeIFrame960x540,
    ] as [String: UIImagePickerController.QualityType])

    // Deprecated

    @objc static var uiImagePickerControllerCameraCaptureMode: RuntimeType { return uiImagePickerController_CameraCaptureMode }
    @objc static var uiImagePickerControllerCameraDevice: RuntimeType { return uiImagePickerController_CameraDevice }
    @objc static var uiImagePickerControllerCameraFlashMode: RuntimeType { return uiImagePickerController_CameraFlashMode }
    @objc static var uiImagePickerControllerImageURLExportPreset: RuntimeType { return uiImagePickerController_ImageURLExportPreset }
    @objc static var uiImagePickerControllerSourceType: RuntimeType { return uiImagePickerController_SourceType }
    @objc static var uiImagePickerControllerQualityType: RuntimeType { return uiImagePickerController_QualityType }

    // MARK: UISplitViewController

    @objc static let uiSplitViewController_DisplayMode = RuntimeType([
        "automatic": .automatic,
        "primaryHidden": .primaryHidden,
        "allVisible": .allVisible,
        "primaryOverlay": .primaryOverlay,
    ] as [String: UISplitViewController.DisplayMode])
    @objc static let uiSplitViewController_PrimaryEdge: RuntimeType = {
        if #available(iOS 11.0, *) {
            #if swift(>=4.2)
                typealias PrimaryEdge = UISplitViewController.PrimaryEdge
            #else
                typealias PrimaryEdge = UISplitViewControllerPrimaryEdge
            #endif
            return RuntimeType([
                "leading": .leading,
                "trailing": .trailing,
            ] as [String: PrimaryEdge])
        }
        return RuntimeType([
            "leading": 0,
            "trailing": 1,
        ] as [String: Int])
    }()

    // Deprecated

    @objc static var uiSplitViewControllerDisplayMode: RuntimeType { return uiSplitViewController_DisplayMode }
    @objc static var uiSplitViewControllerPrimaryEdge: RuntimeType { return uiSplitViewController_PrimaryEdge }

    // MARK: UIVisualEffectView

    @objc static let uiBlurEffect_Style: RuntimeType = {
        let extraDark: UIBlurEffect.Style
        let regular: UIBlurEffect.Style
        let prominent: UIBlurEffect.Style
        if #available(iOS 10.0, *) {
            #if os(tvOS)
                extraDark = .extraDark
            #else
                extraDark = .dark
            #endif
            regular = .regular
            prominent = .prominent
        } else {
            extraDark = .dark
            regular = .light
            prominent = .extraLight
        }
        return RuntimeType([
            "extraLight": .extraLight,
            "light": .light,
            "dark": .dark,
            // TODO: is there any way to warn when using these on an unsupported OS version?
            "extraDark": extraDark,
            "regular": regular,
            "prominent": prominent,
        ] as [String: UIBlurEffect.Style])
    }()

    // Deprecated

    @objc static var uiBlurEffectStyle: RuntimeType { return uiBlurEffect_Style }
}
