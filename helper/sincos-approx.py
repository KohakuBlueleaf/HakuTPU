import torch
import numpy as np
import matplotlib.pyplot as plt

# Set random seed for reproducibility
torch.manual_seed(42)

# Generate data points
x = torch.linspace(0, np.pi, 10000).reshape(-1, 1)
cos_target = torch.cos(x)
sin_target = torch.sin(x)

# Parameters to optimize (initialized randomly)
a_cos = torch.tensor([0.0], requires_grad=True)
b_cos = torch.tensor([0.0], requires_grad=True)
a_sin = torch.tensor([0.0], requires_grad=True)
b_sin = torch.tensor([0.0], requires_grad=True)

# Hyperparameters
learning_rate = 0.001
num_epochs = 1000

# Training loop for cosine approximation
for epoch in range(num_epochs):
    # Forward pass
    y_pred_cos = (a_cos + x**2)**2 + b_cos
    
    # Compute loss
    loss_cos = torch.mean((y_pred_cos - cos_target)**2)
    
    # Backward pass
    loss_cos.backward()
    
    # Update parameters
    with torch.no_grad():
        a_cos -= learning_rate * a_cos.grad
        b_cos -= learning_rate * b_cos.grad
        
        # Zero gradients
        a_cos.grad.zero_()
        b_cos.grad.zero_()
    
    if (epoch + 1) % 2000 == 0:
        print(f'Cosine Epoch [{epoch+1}/{num_epochs}], Loss: {loss_cos.item():.6f}')


# Training loop for sine approximation
for epoch in range(num_epochs):
    # Forward pass
    y_pred_sin = (a_sin + x**2) * -x + b_sin
    
    # Compute loss
    loss_sin = torch.mean((y_pred_sin - sin_target)**2)
    
    # Backward pass
    loss_sin.backward()
    
    # Update parameters
    with torch.no_grad():
        a_sin -= learning_rate * a_sin.grad
        b_sin -= learning_rate * b_sin.grad
        
        # Zero gradients
        a_sin.grad.zero_()
        b_sin.grad.zero_()
    
    if (epoch + 1) % 2000 == 0:
        print(f'Sine Epoch [{epoch+1}/{num_epochs}], Loss: {loss_sin.item():.6f}')

# Print final parameters
print("\nFinal Parameters:")
print(f"Cosine approximation: a = {a_cos.item():.6f}, b = {b_cos.item():.6f}")
print(f"Sine approximation: a = {a_sin.item():.6f}, b = {b_sin.item():.6f}")

# Plotting
plt.figure(figsize=(12, 5))

# Plot cosine approximation
plt.subplot(1, 2, 1)
with torch.no_grad():
    # y_pred_cos = (a_cos + x**2)**2 + b_cos
    y_pred_cos = 1 - x**2 * 0.5 + x**4 * 1/24 - x**6 * 1/720
    
    stage2 = 1/24 - x**2 * 1/720
    stage1 = 0.5 - x**2 * stage2
    y_pred_cos = 1 - x**2 * stage1
plt.plot(x.numpy(), cos_target.numpy(), label='True cos(πx)')
plt.plot(x.numpy(), y_pred_cos.numpy(), '--', label='Approximation')
plt.title('Cosine Approximation')
plt.legend()
plt.grid(True)

# Plot sine approximation
plt.subplot(1, 2, 2)
with torch.no_grad():
    # y_pred_sin = (a_sin + x**2) * -x + b_sin
    y_pred_sin = x - x**3 * 1/6 + x**5 * 1/120
    # y_pred_sin = x * (1 - x**2 * (1/6 - x**2 * (1/120)))
plt.plot(x.numpy(), sin_target.numpy(), label='True sin(πx)')
plt.plot(x.numpy(), y_pred_sin.numpy(), '--', label='Approximation')
plt.title('Sine Approximation')
plt.legend()
plt.grid(True)

plt.tight_layout()
plt.show()