import User from "../models/user.model.js";
import Message from "../models/message.model.js";

// Import GCS upload function
import { uploadToS3 } from "../lib/s3.js"; 

// Import socket-related functions
import { getReceiverSocketId, io } from "../lib/socket.js";

export const getUsersForSidebar = async (req, res) => {
  try {
    const loggedInUserId = req.user._id;
    const filteredUsers = await User.find({ _id: { $ne: loggedInUserId } }).select("-password");

    res.status(200).json(filteredUsers);
  } catch (error) {
    console.error("Error in getUsersForSidebar: ", error.message);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getMessages = async (req, res) => {
  try {
    const { id: userToChatId } = req.params;
    const myId = req.user._id;

    const messages = await Message.find({
      $or: [
        { senderId: myId, receiverId: userToChatId },
        { senderId: userToChatId, receiverId: myId },
      ],
    });

    res.status(200).json(messages);
  } catch (error) {
    console.log("Error in getMessages controller: ", error.message);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const sendMessage = async (req, res) => {
  try {
    const { text, image } = req.body; // `image` is expected as a base64-encoded string
    const { id: receiverId } = req.params;
    const senderId = req.user._id;
    const username = req.user.username; // Assuming the user object contains a `username` field

    let imageUrl;

    if (image) {
      // Extract the MIME type from the base64 header
      const mimeTypeMatch = image.match(/^data:([a-zA-Z0-9]+\/[a-zA-Z0-9-.+]+);base64,/);
      if (!mimeTypeMatch) {
        return res.status(400).json({ error: "Invalid image format" });
      }

      const mimeType = mimeTypeMatch[1]; // Extract MIME type (e.g., "image/png")

      // Convert base64 image to Buffer
      const base64Data = image.split(";base64,").pop(); // Extract the actual base64 data
      const buffer = Buffer.from(base64Data, "base64");

      // Upload the image to GCS with a custom filename
      const publicUrl = await uploadToS3(buffer, senderId, mimeType); // Pass username and MIME type
      imageUrl = publicUrl;
    }

    // Create and save the new message
    const newMessage = new Message({
      senderId,
      receiverId,
      text,
      image: imageUrl,
    });

    await newMessage.save();

    // Emit the new message to the receiver's socket
    const receiverSocketId = getReceiverSocketId(receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit("newMessage", newMessage);
    }

    res.status(201).json(newMessage);
  } catch (error) {
    console.log("Error in sendMessage controller:", error.message);
    res.status(500).json({ error: "Internal server error" });
  }
};